#!/bin/bash
# ============================================================
# Hermes Web UI - 一鍵啟動腳本
# 用法: ./start-hermes-web-ui.sh
# ============================================================

PROJECT_DIR="D:/hermes-web-ui"
LOG_DIR="$HOME/.hermes-web-ui/logs"
SERVER_PORT=8648
CLIENT_PORT=5173

# 創建日誌目錄
mkdir -p "$LOG_DIR"

echo "============================================"
echo "  Hermes Web UI - 啟動中..."
echo "============================================"

# ============================================================
# 步驟 1: 殺死殘留進程
# ============================================================
echo ""
echo "[1/4] 清理殘留進程..."

# 殺死占用端口的進程
NETSTAT_OUTPUT=$(netstat -ano 2>/dev/null | grep "LISTENING" | grep ":$SERVER_PORT " | awk '{print $NF}' | sort -u)
if [ -n "$NETSTAT_OUTPUT" ]; then
  echo "  清理端口 $SERVER_PORT (Server)..."
  for PID in $NETSTAT_OUTPUT; do
    if [ "$PID" != "PID" ] && [ -n "$PID" ]; then
      echo "    → 殺死進程 PID=$PID"
      taskkill //PID $PID //F >/dev/null 2>&1
    fi
  done
fi

NETSTAT_OUTPUT=$(netstat -ano 2>/dev/null | grep "LISTENING" | grep ":$CLIENT_PORT " | awk '{print $NF}' | sort -u)
if [ -n "$NETSTAT_OUTPUT" ]; then
  echo "  清理端口 $CLIENT_PORT (Client)..."
  for PID in $NETSTAT_OUTPUT; do
    if [ "$PID" != "PID" ] && [ -n "$PID" ]; then
      echo "    → 殺死進程 PID=$PID"
      taskkill //PID $PID //F >/dev/null 2>&1
    fi
  done
fi

# 殺死殘留的 node/nodemon/vite 進程
echo "  清理殘留 Node.js 進程..."
ps aux 2>/dev/null | grep -E "(nodemon|vite|ts-node)" | grep -v grep | awk '{print $1}' | while read PID; do
  if [ -n "$PID" ]; then
    echo "    → 殺死進程 PID=$PID"
    kill -9 $PID 2>/dev/null
  fi
done

sleep 2
echo "  ✓ 清理完成"

# ============================================================
# 步驟 2: 設置環境變量
# ============================================================
echo ""
echo "[2/4] 設置環境變量..."
export HERMES_AGENT_ROOT=D:/hermes-agent-main
export HERMES_HOME=$HOME/.hermes
export SESSION_STORE=remote
export PORT=8648
export BIND_HOST=127.0.0.1

# 寫入 .env 文件（供 nodemon 讀取）
cat > "$PROJECT_DIR/.env" << EOF
HERMES_AGENT_ROOT=D:/hermes-agent-main
HERMES_HOME=$HOME/.hermes
SESSION_STORE=remote
PORT=8648
BIND_HOST=127.0.0.1
EOF

echo "  ✓ HERMES_AGENT_ROOT=$HERMES_AGENT_ROOT"
echo "  ✓ HERMES_HOME=$HERMES_HOME"
echo "  ✓ SESSION_STORE=$SESSION_STORE"

# ============================================================
# 步驟 3: 啟動 Server（後台）
# ============================================================
echo ""
echo "[3/4] 啟動 Server (端口 $SERVER_PORT)..."

cd "$PROJECT_DIR"
npm run dev:server > "$LOG_DIR/server.log" 2>&1 &
SERVER_PID=$!
echo "  ✓ Server 已啟動 (PID=$SERVER_PID)"
echo "  日誌: $LOG_DIR/server.log"

# 等待 Server 啟動
echo "  等待 Server 就緒..."
for i in $(seq 1 30); do
  sleep 1
  if netstat -ano 2>/dev/null | grep -q ":$SERVER_PORT .*LISTENING"; then
    echo "  ✓ Server 已就緒 (端口 $SERVER_PORT)"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "  ✗ Server 啟動超時！請檢查日誌: $LOG_DIR/server.log"
    exit 1
  fi
done

# ============================================================
# 步驟 4: 啟動 Client（後台）
# ============================================================
echo ""
echo "[4/4] 啟動 Client (端口 $CLIENT_PORT)..."

cd "$PROJECT_DIR"
npm run dev:client > "$LOG_DIR/client.log" 2>&1 &
CLIENT_PID=$!
echo "  ✓ Client 已啟動 (PID=$CLIENT_PID)"
echo "  日誌: $LOG_DIR/client.log"

# 等待 Client 啟動
echo "  等待 Client 就緒..."
for i in $(seq 1 30); do
  sleep 1
  if netstat -ano 2>/dev/null | grep -q ":$CLIENT_PORT .*LISTENING"; then
    echo "  ✓ Client 已就緒 (端口 $CLIENT_PORT)"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "  ⚠ Client 啟動超時，但可能已啟動在其他端口"
    echo "  請檢查日誌: $LOG_DIR/client.log"
    break
  fi
done

# ============================================================
# 完成
# ============================================================
sleep 2
echo ""
echo "============================================"
echo "  ✓ 啟動完成！"
echo "============================================"
echo ""
echo "  訪問地址:"
CLIENT_PORT_ACTUAL=$(netstat -ano 2>/dev/null | grep "LISTENING" | grep "vite" | head -1 | awk '{print $2}' | sed 's/.*://' || echo $CLIENT_PORT)
echo "    Frontend:  http://localhost:${CLIENT_PORT_ACTUAL}/"
echo "    Backend:   http://localhost:${SERVER_PORT}/"
echo ""
echo "  Token (如需要):"
echo "    43b734458dba599f5c4cb00cfea0faabee41c80350a7d4a44f7cb3999ff03080"
echo ""
echo "  日誌文件:"
echo "    Server: $LOG_DIR/server.log"
echo "    Client: $LOG_DIR/client.log"
echo ""
echo "  停止服務: 運行 ./stop-hermes-web-ui.sh"
echo "============================================"

# 保存 PID 到文件（供 stop 腳本使用）
echo "$SERVER_PID" > "$LOG_DIR/.server.pid"
echo "$CLIENT_PID" > "$LOG_DIR/.client.pid"

# 保持腳本運行（可選，按 Ctrl+C 停止）
# wait
