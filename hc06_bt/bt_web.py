#!/usr/bin/env python3
"""HC-06 canli sohbet — web + Bluetooth koprusu."""
import argparse
import json
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
sys.path.insert(0, str(ROOT))

from neo_gps_pynq import MmioUart, ensure_fpga_operating, load_overlay_sysfs

lock = threading.Lock()
state = {"messages": [], "tx_count": 0, "rx_count": 0}
uart_ref = {"uart": None}
MAX_MSG = 200


def add_message(text: str, src: str, who: str) -> None:
    with lock:
        state["messages"] = (state["messages"] + [{
            "who": who,
            "text": text,
            "src": src,
            "ts": int(time.time()),
        }])[-MAX_MSG:]
        if src == "bt":
            state["rx_count"] += 1
        else:
            state["tx_count"] += 1


def uart_reader():
    uart = uart_ref["uart"]
    buf = bytearray()
    while uart:
        b = uart.read_byte()
        if b is None:
            time.sleep(0.005)
            continue
        if b in (0x0A, 0x0D):
            if buf:
                line = buf.decode("utf-8", errors="replace")
                add_message(line, "bt", "Telefon")
                print(f"BT< {line}")
                buf.clear()
        elif b >= 32:
            buf.append(b)
        if len(buf) > 256:
            buf.clear()


def send_bt(text: str) -> bool:
    uart = uart_ref["uart"]
    if not uart:
        return False
    for ch in text:
        uart.write_byte(ord(ch))
    uart.write_byte(0x0D)
    uart.write_byte(0x0A)
    return True


HTML = """<!DOCTYPE html>
<html lang="tr"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>PYNQ Sohbet</title>
<style>
*{box-sizing:border-box}
body{font-family:system-ui,-apple-system,sans-serif;background:#0b141a;color:#e9edef;margin:0;min-height:100vh;display:flex;flex-direction:column}
header{background:#202c33;padding:.75rem 1rem;border-bottom:1px solid #2a3942}
header h1{font-size:1rem;margin:0;color:#00a884}
header p{margin:.25rem 0 0;font-size:.8rem;color:#8696a0}
#chat{flex:1;overflow:auto;padding:1rem;display:flex;flex-direction:column;gap:.5rem}
.bubble{max-width:85%;padding:.55rem .75rem;border-radius:8px;font-size:.95rem;line-height:1.35;word-break:break-word}
.bubble .who{font-size:.7rem;opacity:.75;margin-bottom:.15rem}
.bubble.web{align-self:flex-end;background:#005c4b}
.bubble.bt{align-self:flex-start;background:#202c33}
footer{background:#202c33;padding:.75rem;border-top:1px solid #2a3942}
.name-row{margin-bottom:.5rem}
.name-row input{width:100%;padding:.5rem;border-radius:8px;border:1px solid #2a3942;background:#2a3942;color:#e9edef}
.row{display:flex;gap:.5rem}
.row input{flex:1;padding:.65rem;border-radius:24px;border:none;background:#2a3942;color:#e9edef}
button{background:#00a884;border:none;color:#fff;border-radius:50%;width:44px;height:44px;font-size:1.2rem;cursor:pointer;flex-shrink:0}
</style></head><body>
<header>
<h1>PYNQ · HC-06 Sohbet</h1>
<p>Web mesajlari Bluetooth telefona gider · Telefondan gelenler burada gorunur</p>
</header>
<div id="chat"></div>
<footer>
<div class="name-row"><input id="name" placeholder="Adin (ornek: Ayse)" maxlength="24"></div>
<div class="row">
<input id="msg" placeholder="Mesaj yaz..." maxlength="500" autocomplete="off">
<button onclick="send()" title="Gonder">&#10148;</button>
</div>
</footer>
<script>
const nameEl=document.getElementById('name');
const msgEl=document.getElementById('msg');
nameEl.value=localStorage.getItem('pynq_name')||'';
nameEl.onchange=()=>localStorage.setItem('pynq_name',nameEl.value.trim());
msgEl.onkeydown=e=>{if(e.key==='Enter')send();};

function esc(s){return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}

async function poll(){
  const r=await fetch('/data'); const j=await r.json();
  const el=document.getElementById('chat');
  el.innerHTML=j.messages.map(m=>{
    const cls=m.src==='bt'?'bt':'web';
    return '<div class="bubble '+cls+'"><div class="who">'+esc(m.who)+'</div>'+esc(m.text)+'</div>';
  }).join('');
  el.scrollTop=el.scrollHeight;
}
async function send(){
  const name=(nameEl.value||'Misafir').trim()||'Misafir';
  const text=msgEl.value.trim();
  if(!text)return;
  localStorage.setItem('pynq_name',name);
  msgEl.value='';
  await fetch('/send?name='+encodeURIComponent(name)+'&text='+encodeURIComponent(text),{method:'POST'});
  poll();
}
setInterval(poll,700); poll();
</script></body></html>"""


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_GET(self):
        if self.path == "/" or self.path.startswith("/?"):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML.encode())
        elif self.path == "/data":
            with lock:
                body = json.dumps(state)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body.encode())
        else:
            self.send_error(404)

    def do_POST(self):
        if self.path.startswith("/send"):
            from urllib.parse import urlparse, parse_qs
            q = parse_qs(urlparse(self.path).query)
            text = q.get("text", [""])[0].strip()
            name = q.get("name", ["Web"])[0].strip() or "Web"
            if text:
                add_message(text, "web", name)
                send_bt(text)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_error(404)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8082)
    ap.add_argument("--skip-overlay", action="store_true")
    args = ap.parse_args()

    bin_path = ROOT / "gps_uart.bin"
    if not args.skip_overlay and bin_path.is_file():
        load_overlay_sysfs(bin_path)
    ensure_fpga_operating()

    uart_ref["uart"] = MmioUart()
    threading.Thread(target=uart_reader, daemon=True).start()

    srv = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print(f"[OK] HC-06 sohbet: http://0.0.0.0:{args.port}")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        if uart_ref["uart"]:
            uart_ref["uart"].close()


if __name__ == "__main__":
    main()
