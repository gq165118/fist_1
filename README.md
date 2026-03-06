# Hello CLI

A simple command line tool that greets you.

## Demo Scripts

Run the demo hello script:

```bash
bash scripts/hello.sh
# Output: hello claw

bash scripts/hello2.sh
# Output: hello claw 2
```

---

# ClawTodo

A simple CLI todo list application.

## 如何运行

```bash
# Add a new todo
python3 -m clawtodo add "buy milk"

# List all todos
python3 -m clawtodo list

# Mark a todo as done (by id)
python3 -m clawtodo done 1

# List again to see done status
python3 -m clawtodo list
```

## 如何测试

```bash
python3 -m unittest -q
```

## 数据存储

数据保存在项目根目录的 `.clawtodo.json` 文件中。
