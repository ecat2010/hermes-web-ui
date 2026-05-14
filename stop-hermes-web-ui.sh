#!/bin/bash
# ============================================================
# Hermes Web UI - 一鍵關閉腳本
# 用法: ./stop-hermes-web-ui.sh
# ============================================================

LOG_DIR="$HOME/.hermes-web-ui/logs"
SERVER_PORT=8648
CLIENT_PORT=5173

echo "============================================"
echo "  Hermes Web UI - 關閉中..."
echo "============================================"

KILLED_COUNT=0

# ============================================================
# 方法 1: 讀取 PID 文件並殺死進程
# ============================================================
echo ""
echo "[1/4] 從 PID 文件停止進程..."

if [ -f "$LOG_DIR/.server.pid" ]; then
  SERVER_PID=$(cat "$LOG_DIR/.server.pid")
  if [ -n "$SERVER_PID" ]; then
    echo "  停止 Server (PID=$SERVER_PID)..."
    kill -9 $SERVER_PID 2>/dev/null && echo "    ✓ 已停止" && KILLED_COUNT=$((KILLED_COUNT + 1)) || echo "    ✗ 進程不存在"
  fi
  rm -f "$LOG_DIR/.server.pid"
fi

if [ -f "$LOG_DIR/.client.pid" ]; then
  CLIENT_PID=$(cat "$LOG_DIR/.client.pid")
  if [ -n "$CLIENT_PID" ]; then
    echo "  停止 Client (PID=$CLIENT_PID)..."
    kill -9 $CLIENT_PID 2>/dev/null && echo "    ✓ 已停止" && KILLED_COUNT=$((KILLED_COUNT + 1)) || echo "    ✗ 進程不存在"
  fi
  rm -f "$LOG_DIR/.client.pid"
fi

# ============================================================
# 方法 2: 殺死占用端口的進程
# ============================================================
echo ""
echo "[2/4] 清理占用端口的進程..."

NETSTAT_OUTPUT=$(netstat -ano 2>/dev/null | grep "LISTENING" | grep ":$SERVER_PORT " | awk '{print $NF}' | sort -u)
if [ -n "$NETSTAT_OUTPUT" ]; then
  echo "  清理端口 $SERVER_PORT..."
  for PID in $NETSTAT_OUTPUT; do
    if [ "$PID" != "PID" ] && [ -n "$PID" ]; then
      echo "    → 殺死進程 PID=$PID"
      taskkill //PID $PID //F >/dev/null 2>&1 && KILLED_COUNT=$((KILLED_COUNT + 1))
    fi
  done
else
  echo "  端口 $SERVER_PORT 未被占用"
fi

NETSTAT_OUTPUT=$(netstat -ano 2>/dev/null | grep "LISTENING" | grep ":$CLIENT_PORT " | awk '{print $NF}' | sort -u)
if [ -n "$NETSTAT_OUTPUT" ]; then
  echo "  清理端口 $CLIENT_PORT..."
  for PID in $NETSTAT_OUTPUT; do
    if [ "$PID" != "PID" ] && [ -n "$PID" ]; then
      echo "    → 殺死進程 PID=$PID"
      taskkill //PID $PID //F >/dev/null 2>&1 && KILLED_COUNT=$((KILLED_COUNT + 1))
    fi
  done
else
  echo "  端口 $CLIENT_PORT 未被占用"
fi

# ============================================================
# 方法 3: 殺死 node/nodemon/vite 進程
# ============================================================
echo ""
echo "[3/4] 清理殘留 Node.js 進程..."

PROCESSES=$(ps aux 2>/dev/null | grep -E "(nodemon|vite|ts-node)" | grep -v grep | awk '{print $1}' | sort -u)
if [ -n "$PROCESSES" ]; then
  for PID in $PROCESSES; do
    if [ -n "$PID" ]; then
      echo "  → 殺死進程 PID=$PID"
      kill -9 $PID 2>/dev/null && KILLED_COUNT=$((KILLED_COUNT + 1))
    fi
  done
else
  echo "  沒有殘留進程"
fi

# ============================================================
# 方法 4: 殺死 agent-bridge (Python)
# ============================================================
echo ""
echo "[4/4] 清理 Agent Bridge 進程..."

AGENT_BRIDGE_PIDS=$(ps aux 2>/dev/null | grep "hermes_bridge.py" | grep -v grep | awk '{print $1}' | sort -u)
if [ -n "$AGENT_BRIDGE_PIDS" ]; then
  for PID in $AGENT_BRIDGE_PIDS; do
    if [ -n "$PID" ]; then
      echo "  → 殺死 Agent Bridge PID=$PID"
      kill -9 $PID 2>/dev/null && KILLED_COUNT=$((KILLED_COUNT + 1))
    fi
  done
else
  echo "  沒有 Agent Bridge 進程"
fi

# ============================================================
# 完成
# ============================================================
sleep 1
echo ""
echo "============================================"
if [ $KILLED_COUNT -gt 0 ]; then
  echo "  ✓ 已停止 $KILLED_COUNT 個進程"
else
  echo "  ✗ 沒有找到運行中的進程"
fi
echo "============================================"
echo ""
echo "  日誌文件已保留:"
echo "    $LOG_DIR/server.log"
echo "    $LOG_DIR/client.log"
echo ""
echo "  重新啟動: 運行 ./start-hermes-web-ui.sh"
echo "============================================"
