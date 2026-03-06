"""ClawTodo - A simple CLI todo list."""

import json
import os
import sys
from pathlib import Path

DATA_FILE = Path(__file__).parent / ".clawtodo.json"


def load_todos():
    """Load todos from JSON file."""
    if not DATA_FILE.exists():
        return []
    with open(DATA_FILE, "r") as f:
        return json.load(f)


def save_todos(todos):
    """Save todos to JSON file."""
    with open(DATA_FILE, "w") as f:
        json.dump(todos, f, indent=2)


def add_todo(text):
    """Add a new todo."""
    todos = load_todos()
    todo_id = len(todos) + 1
    todos.append({"id": todo_id, "text": text, "done": False})
    save_todos(todos)
    print(f"Added: {text}")


def list_todos():
    """List all todos."""
    todos = load_todos()
    if not todos:
        print("No todos yet.")
        return
    for todo in todos:
        status = "[x]" if todo["done"] else "[ ]"
        print(f"{todo['id']}. {status} {todo['text']}")


def done_todo(todo_id):
    """Mark a todo as done."""
    todos = load_todos()
    found = False
    for todo in todos:
        if todo["id"] == todo_id:
            todo["done"] = True
            found = True
            break
    if found:
        save_todos(todos)
        print(f"Done: {todo_id}")
    else:
        print(f"Todo {todo_id} not found.")


def main():
    if len(sys.argv) < 2:
        print("Usage: python -m clawtodo <add|list|done> [args]")
        sys.exit(1)

    command = sys.argv[1]

    if command == "add":
        if len(sys.argv) < 3:
            print("Usage: python -m clawtodo add <text>")
            sys.exit(1)
        add_todo(" ".join(sys.argv[2:]))
    elif command == "list":
        list_todos()
    elif command == "done":
        if len(sys.argv) < 3:
            print("Usage: python -m clawtodo done <id>")
            sys.exit(1)
        try:
            done_todo(int(sys.argv[2]))
        except ValueError:
            print("Error: id must be a number")
            sys.exit(1)
    else:
        print(f"Unknown command: {command}")
        print("Usage: python -m clawtodo <add|list|done> [args]")
        sys.exit(1)


if __name__ == "__main__":
    main()
