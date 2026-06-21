#!/bin/bash
cd "$(dirname "$0")"
exec sudo python3 bt_web.py "$@"
