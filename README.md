# Hello CLI

A simple command line tool that greets you.

## Installation

```bash
pip install -e .
```

Or just run directly:

```bash
python hello.py <name>
```

## Usage

```bash
python hello.py World
# Output: Hello, World!

python hello.py Alice
# Output: Hello, Alice!
```

## Testing

```bash
python -m pytest -q
```

## 🐍 贪吃蛇游戏

手机上可玩的贪吃蛇小游戏。

### 运行方式

用浏览器打开 `snake.html` 即可开始游戏：

```bash
# macOS
open snake.html

# 或启动一个本地服务器
python3 -m http.server 8000
# 然后访问 http://localhost:8000/snake.html
```

### 操作方式

- **手机**: 触摸屏幕滑动控制方向
- **电脑**: 方向键 或 WASD 控制

### 游戏规则

- 吃到红色食物 +10 分
- 撞墙或撞到自己游戏结束
- 点击"再来一局"重新开始

## Demo Scripts

Run the demo hello script:

```bash
bash scripts/hello.sh
# Output: hello claw

bash scripts/hello2.sh
# Output: hello claw 2
```
