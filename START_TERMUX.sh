#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")"
if ! command -v python >/dev/null 2>&1; then
  echo "Python نصب نیست. ابتدا اجرا کن: pkg install python -y"
  exit 1
fi
if [ -f .termux-server.pid ] && kill -0 "$(cat .termux-server.pid)" 2>/dev/null; then
  echo "TradeNova ظاهراً از قبل اجراست. مرورگر را با نشانی زیر باز کن:"
  echo "http://127.0.0.1:8000/"
  command -v termux-open-url >/dev/null 2>&1 && termux-open-url "http://127.0.0.1:8000/" || true
  exit 0
fi
echo "TradeNova Demo در حال اجراست..."
echo "پس از شروع سرور، مرورگر را باز کن: http://127.0.0.1:8000/"
echo "برای توقف، در همین پنجره Ctrl+C را بزن."
python telegram-server.py
