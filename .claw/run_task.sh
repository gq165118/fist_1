#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config: adjust if needed
# =========================
REPO_DIR="/Users/gq/claude_coding_workspace/proj_1"

# OpenClaw Hooks -> Telegram (coding agent)
export OPENCLAW_URL="${OPENCLAW_URL:-http://127.0.0.1:18789/hooks/agent}"
export OPENCLAW_HOOKS_TOKEN="${OPENCLAW_HOOKS_TOKEN:-testhooks-123456}"
export OPENCLAW_AGENT_ID="${OPENCLAW_AGENT_ID:-coding}"
export OPENCLAW_TELEGRAM_TO="${OPENCLAW_TELEGRAM_TO:-8767678598}"

NOTIFY="$HOME/.claude/hooks/openclaw_notify.sh"

# =========================
# Input
# =========================
TASK_NAME="${1:-}"
if [[ -z "$TASK_NAME" ]]; then
  echo "Usage: $0 <task_name>" >&2
  exit 2
fi

BRANCH="feature/${TASK_NAME}"

# =========================
# Helpers
# =========================
notify() {
  # avoid failing the whole script if notification fails
  "$NOTIFY" "$1" || true
}

run_cmd() {
  # echo and run
  echo "+ $*" >&2
  "$@"
}

# =========================
# Start
# =========================
run_cmd cd "$REPO_DIR"

notify "🚀 开始任务：$TASK_NAME
• Repo: $(basename "$REPO_DIR")
• Branch: $BRANCH
• Dir: $REPO_DIR"

# 1) checkout branch
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  run_cmd git checkout "$BRANCH"
else
  run_cmd git checkout -b "$BRANCH"
fi

# 2) 运行 Claude Code（这里给你两种写法，二选一）

# --- 2A) 你已经有自己的任务入口（例如你原来就是这样跑 task_demo 的）
# 说明：把下面这行替换成你当前的“调用 Claude Code 执行任务”的命令即可
# run_cmd claude "Implement task: $TASK_NAME"   # <- 示例，占位

# --- 2B) 用一个任务说明文件驱动（推荐：省 token，输入稳定）
# 约定任务文件：.claw/tasks/<task>.md
TASK_FILE="$REPO_DIR/.claw/tasks/${TASK_NAME}.md"
if [[ -f "$TASK_FILE" ]]; then
  notify "🧾 读取任务文件：$TASK_FILE"
  # 这里请替换成你实际 Claude Code 的命令
  # 常见用法示例（按你本地claude命令实际参数改）：
  # run_cmd claude -p "$(cat "$TASK_FILE")"
  run_cmd claude "$(cat "$TASK_FILE")"
else
  notify "⚠️ 未找到任务文件：$TASK_FILE
将直接把任务名作为指令执行（你可以后续补齐任务文件）"
  run_cmd claude "Task: $TASK_NAME"
fi

# 3) 测试（按你项目实际情况改）
# - 如果你是 bash 脚本项目，可简单跑个 smoke test
if [[ -x "$REPO_DIR/scripts/hello.sh" ]]; then
  out="$(bash "$REPO_DIR/scripts/hello.sh" || true)"
  notify "🧪 测试输出（scripts/hello.sh）：
$out"
fi

# 4) commit（如果有改动）
if [[ -n "$(git status --porcelain)" ]]; then
  run_cmd git add -A
  run_cmd git commit -m "$TASK_NAME"
else
  notify "ℹ️ 工作区无变更：无需 commit"
fi

# 5) push
run_cmd git push -u origin "$BRANCH"

# =========================
# 6) ✅ 你问的那段：必须放在 git push 之后（就在这里）
# =========================
REPO_URL="$(git remote get-url origin | sed -e 's#git@github.com:#https://github.com/#' -e 's#\.git$##')"
CUR_BRANCH="$(git branch --show-current)"
COMMIT="$(git rev-parse --short HEAD)"

notify "✅ 已推送到 GitHub
• Repo: $REPO_URL
• Branch: $CUR_BRANCH
• Commit: $COMMIT
• Compare: $REPO_URL/compare/$CUR_BRANCH?expand=1"

notify "🎉 任务完成：$TASK_NAME"