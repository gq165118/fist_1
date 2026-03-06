"""Tests for ClawTodo."""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import clawtodo


class TestClawTodo(unittest.TestCase):
    """Test cases for ClawTodo."""

    def setUp(self):
        """Set up test environment."""
        self.test_file = Path(tempfile.gettempdir()) / ".clawtodo_test.json"
        clawtodo.DATA_FILE = self.test_file
        # Clear any existing todos
        if self.test_file.exists():
            os.remove(self.test_file)

    def tearDown(self):
        """Clean up test environment."""
        if self.test_file.exists():
            os.remove(self.test_file)

    def test_add_todo(self):
        """Test adding a todo."""
        clawtodo.add_todo("buy milk")
        todos = clawtodo.load_todos()
        self.assertEqual(len(todos), 1)
        self.assertEqual(todos[0]["text"], "buy milk")
        self.assertFalse(todos[0]["done"])

    def test_list_todos(self):
        """Test listing todos."""
        clawtodo.add_todo("task 1")
        clawtodo.add_todo("task 2")
        todos = clawtodo.load_todos()
        self.assertEqual(len(todos), 2)

    def test_done_todo(self):
        """Test marking a todo as done."""
        clawtodo.add_todo("test task")
        clawtodo.done_todo(1)
        todos = clawtodo.load_todos()
        self.assertTrue(todos[0]["done"])

    def test_done_nonexistent(self):
        """Test marking a non-existent todo."""
        clawtodo.add_todo("test")
        result = clawtodo.done_todo(999)
        # Should print error message but not crash


if __name__ == "__main__":
    unittest.main()
