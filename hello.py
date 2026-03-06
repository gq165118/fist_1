#!/usr/bin/env python3
"""Hello CLI - A simple command line tool."""

import argparse


def main():
    parser = argparse.ArgumentParser(description="Say hello to someone")
    parser.add_argument("name", help="Name of the person to greet")
    args = parser.parse_args()
    print(f"Hello, {args.name}!")


if __name__ == "__main__":
    main()
