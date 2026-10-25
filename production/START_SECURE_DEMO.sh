#!/data/data/com.termux/files/usr/bin/bash
set -eu
cd "$(dirname "$0")/.."
echo 'Starting isolated server-side PAPER engine on 127.0.0.1:8765'
echo 'Set TRADENOVA_BOT_TOKEN in your own environment; never paste it into chat.'
python production/secure_demo_backend.py
