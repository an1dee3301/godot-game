#!/usr/bin/env python3
"""Run the full heist soak with a wall-clock and engine-error gate."""

import pathlib
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
COMMAND = [
    "/Applications/Godot.app/Contents/MacOS/Godot",
    "--headless",
    "--path",
    str(ROOT),
    "--fixed-fps",
    "60",
    "--disable-vsync",
    "-s",
    "res://tests/playthrough_test.gd",
]


def main() -> int:
    try:
        result = subprocess.run(
            COMMAND,
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=89,
            check=False,
        )
    except subprocess.TimeoutExpired as error:
        if error.stdout:
            sys.stdout.write(error.stdout.decode(errors="replace"))
        print("FAIL: playthrough exceeded 89 seconds")
        return 1
    sys.stdout.write(result.stdout)
    if "SCRIPT ERROR:" in result.stdout:
        print("FAIL: Godot reported SCRIPT ERROR")
        return 1
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
