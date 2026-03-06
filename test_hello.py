"""Tests for hello CLI."""

import subprocess
import sys


def test_hello():
    result = subprocess.run(
        [sys.executable, "hello.py", "World"],
        capture_output=True,
        text=True,
        cwd="/Users/gq/claude_coding_workspace/proj_1"
    )
    assert result.returncode == 0
    assert result.stdout.strip() == "Hello, World!"


def test_hello_name():
    result = subprocess.run(
        [sys.executable, "hello.py", "Alice"],
        capture_output=True,
        text=True,
        cwd="/Users/gq/claude_coding_workspace/proj_1"
    )
    assert result.returncode == 0
    assert result.stdout.strip() == "Hello, Alice!"
