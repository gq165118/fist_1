#!/usr/bin/env bash
set -euo pipefail

TASK="${1:-}"
if [[ -z "$TASK" ]]; then
  echo "Usage: .claw/run_task.sh <task_name_without_ext>"
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_FILE="$ROOT/.claw/tasks/${TASK}.md"

# --- Extract TEST command from task file ---
TEST_CMD="$(awk '
  BEGIN{in_test=0; in_code=0}
  /^##[[:space:]]+Test[[:space:]]*$/ {in_test=1; next}
  in_test && /^##[[:space:]]+/ {exit}                  # next heading -> stop
  in_test && /^```bash[[:space:]]*$/ {in_code=1; next}  # code block start
  in_code && /^```[[:space:]]*$/ {exit}                # code block end -> stop
  in_code {print}
' "$TASK_FILE" | sed -e 's/[[:space:]]\+$//' )"

# 防呆：必须有测试命令
if [[ -z "${TEST_CMD//[[:space:]]/}" ]]; then
  ~/.claude/hooks/openclaw_notify.sh "🟨 未找到 Test 命令（请在任务文件里写：## Test + 代码块 ```bash ... ```）\n• Task: $TASK_NAME"
  exit 2
fi

if [[ ! -f "$TASK_FILE" ]]; then
  echo "Task file not found: $TASK_FILE"
  exit 1
fi

cd "$ROOT"

# ---- Env defaults (你也可以在外部 export 覆盖) ----
export OPENCLAW_URL="${OPENCLAW_URL:-http://127.0.0.1:18789/hooks/agent}"
export OPENCLAW_AGENT_ID="${OPENCLAW_AGENT_ID:-coding}"
export OPENCLAW_TELEGRAM_TO="${OPENCLAW_TELEGRAM_TO:-8767678598}"
export OPENCLAW_HOOKS_TOKEN="${OPENCLAW_HOOKS_TOKEN:-}"

NOTIFY="${HOME}/.claude/hooks/openclaw_notify.sh"

# ---- 1) 从任务单解析 Branch/Commit（简单 grep；写得规整就很稳）----
BRANCH="$(grep -E '^[[:space:]]*-[[:space:]]*Branch:[[:space:]]*' "$TASK_FILE" \
  | head -n1 \
  | sed -E 's/^[[:space:]]*-[[:space:]]*Branch:[[:space:]]*//; s/[[:space:]]+$//')"

COMMIT_MSG="$(grep -E '^[[:space:]]*-[[:space:]]*Commit message:[[:space:]]*' "$TASK_FILE" \
  | head -n1 \
  | sed -E 's/^[[:space:]]*-[[:space:]]*Commit message:[[:space:]]*//; s/[[:space:]]+$//')"

if [[ -z "${BRANCH}" ]]; then
  BRANCH="feature/${TASK}"
fi
if [[ -z "${COMMIT_MSG}" ]]; then
  COMMIT_MSG="feat: ${TASK}"
fi

"$NOTIFY" "🟦 任务开始：${TASK}
• Dir: ${ROOT}
• Branch: ${BRANCH}"

# ---- 2) Git checkout/reset branch ----
git fetch -q origin || true

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git checkout -q "${BRANCH}"
else
  git checkout -q -b "${BRANCH}"
fi

"$NOTIFY" "🟨 已切换分支：${BRANCH}"

# ---- 3) 调 Claude Code（headless）真正完成“设计→编码” ----
# 关键：用 claude -p 读取任务单全文（非交互，适合自动化）
# 你需要本机已经能运行 `claude` 命令（Claude Code CLI）
PROMPT="$(cat "$TASK_FILE")"

# 可选：把 prompt 也写入日志文件，便于回溯
mkdir -p "$ROOT/.claw/logs"
LOGFILE="$ROOT/.claw/logs/${TASK}.claude.log"

set +e
claude -p "$PROMPT" | tee "$LOGFILE"
CLAUDE_RC=${PIPESTATUS[0]}
set -e

if [[ $CLAUDE_RC -ne 0 ]]; then
  "$NOTIFY" "🟥 Claude Code 执行失败（exit=${CLAUDE_RC}）
• Task: ${TASK}
• Log: .claw/logs/${TASK}.claude.log"
  exit $CLAUDE_RC
fi

# ---- 4) 跑测试（从任务单 Commands/Tests 里取；这里先做一个最小版本：尝试提取每行 '- ' 命令）----
# 你如果想更严格，可以把 Tests 固定为单行 `- <command>`
TEST_CMDS="$(awk '
  BEGIN{inTests=0}
  /^### Tests/{inTests=1; next}
  /^### /{if(inTests) exit}
  {if(inTests) print}
' "$TASK_FILE" | sed -E 's/^\s*-\s*//g' | sed '/^\s*$/d')"

if [[ -z "$TEST_CMDS" ]]; then
  TEST_CMDS='echo "no tests"'
fi

"$NOTIFY" "🧪 开始测试：
$TEST_CMDS"

set +e
bash -lc "$TEST_CMDS"
TEST_RC=$?
set -e

if [[ $TEST_RC -ne 0 ]]; then
  "$NOTIFY" "🟥 测试失败（exit=${TEST_RC}）
• Task: ${TASK}
• Branch: ${BRANCH}"
  exit $TEST_RC
fi

"$NOTIFY" "🟩 测试通过"

# ---- 5) 提交 & push ----
git add -A

if git diff --cached --quiet; then
  "$NOTIFY" "🟦 无变更可提交（任务可能只做了分析/未落地修改）
• Task: ${TASK}
• Branch: ${BRANCH}"
else
  git commit -m "$COMMIT_MSG"
fi

git push -u origin "$BRANCH"

REPO_URL="$(git remote get-url origin | sed -e 's#git@github.com:#https://github.com/#' -e 's#\.git$##')"
CUR_BRANCH="$(git branch --show-current)"
COMMIT="$(git rev-parse --short HEAD)"

"$NOTIFY" "✅ 已推送到 GitHub
• Repo: $REPO_URL
• Branch: $CUR_BRANCH
• Commit: $COMMIT
• Compare: $REPO_URL/compare/$CUR_BRANCH?expand=1"

echo "Done."