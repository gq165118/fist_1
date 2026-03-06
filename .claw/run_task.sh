#!/usr/bin/env bash
set -euo pipefail

TASK="${1:-}"
if [[ -z "$TASK" ]]; then
  echo "Usage: .claw/run_task.sh <task_name>"
  exit 2
fi

# ----- OpenClaw hooks env (you can override when calling) -----
: "${OPENCLAW_URL:=http://127.0.0.1:18789/hooks/agent}"
: "${OPENCLAW_HOOKS_TOKEN:=}"
: "${OPENCLAW_AGENT_ID:=coding}"
: "${OPENCLAW_TELEGRAM_TO:=8767678598}"

notify() {
  # msg in $1
  if [[ -n "${OPENCLAW_HOOKS_TOKEN}" ]]; then
    OPENCLAW_URL="$OPENCLAW_URL" \
    OPENCLAW_HOOKS_TOKEN="$OPENCLAW_HOOKS_TOKEN" \
    OPENCLAW_AGENT_ID="$OPENCLAW_AGENT_ID" \
    OPENCLAW_TELEGRAM_TO="$OPENCLAW_TELEGRAM_TO" \
    ~/.claude/hooks/openclaw_notify.sh "$1" >/dev/null || true
  fi
}

ROOT="$(pwd)"
notify "🟦 任务开始：$TASK
• Dir: $ROOT"

# ----- Create/checkout branch -----
BRANCH="feature/${TASK}"
git checkout -B "$BRANCH"

notify "🟨 已切换分支：$BRANCH"

# ----- Run Claude Code to implement task -----
# 你可以把 task 文件放在 .claw/tasks/${TASK}.md，然后让 claude 读取它，省 token
TASK_FILE=".claw/tasks/${TASK}.md"
if [[ ! -f "$TASK_FILE" ]]; then
  notify "⚠️ 未找到任务文件：$TASK_FILE
我将继续，但建议你创建它以固定输入格式。"
fi

# Claude Code（示例）：如果你用的是 `claude` 命令，把下面这行换成你实际可用的调用方式
# 例如：claude -p "$(cat "$TASK_FILE")"
if command -v claude >/dev/null 2>&1; then
  if [[ -f "$TASK_FILE" ]]; then
    claude -p "$(cat "$TASK_FILE")"
  else
    claude -p "Task: ${TASK}. Please implement according to repo conventions."
  fi
else
  notify "⚠️ 未检测到 claude CLI（command not found: claude）。
请把 run_task.sh 里的 Claude 调用改成你本机实际的 Claude Code 启动命令。"
fi

# ----- Tests (customize) -----
# 如果项目没测试，这段可以先不失败：你可以改成你的实际测试命令
if [[ -f package.json ]]; then
  npm test
elif [[ -f Makefile ]]; then
  make test || true
else
  # no-op
  true
fi

notify "🟩 测试步骤已执行（或无测试）。"

# ----- Commit -----
git add -A
if git diff --cached --quiet; then
  notify "⚠️ 没有变更可提交（git diff --cached 为空）。任务可能未产生修改。"
else
  git commit -m "feat: ${TASK}"
fi

# ----- Push -----
git push -u origin "$BRANCH"

REPO_URL=$(git remote get-url origin | sed -e 's#git@github.com:#https://github.com/#' -e 's#\.git$##')
COMMIT=$(git rev-parse --short HEAD)

notify "✅ 已推送到 GitHub
• Repo: $REPO_URL
• Branch: $BRANCH
• Commit: $COMMIT
• Compare: $REPO_URL/compare/$BRANCH?expand=1"

echo "Done."
