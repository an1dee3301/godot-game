#!/usr/bin/env python3
"""Token/task usage report for the Red Light, Blue Light build.

Reads the local session logs of both agents and writes usage/USAGE_LOG.md:
  * Claude Code: ~/.claude/projects/<project>/<session>.jsonl (per-message `usage`)
  * Codex:       ~/.codex/sessions/**/rollout-*.jsonl (cumulative `token_count` events)

Re-run any time:  python3 usage/usage_report.py
Other builds:     python3 usage/usage_report.py --session <id> --since <iso> --cwd <dir name> --title <name> --out <file>
"""
import argparse
import glob
import json
import os
from collections import Counter
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
CLAUDE_SESSION = "f1e9cbed-a9ee-4d2e-bcb7-60fc11ca3b5b"
CLAUDE_LOG = os.path.expanduser(
    f"~/.claude/projects/-Users-andytran-Coding-Godot/{CLAUDE_SESSION}.jsonl")
CODEX_GLOB = os.path.expanduser("~/.codex/sessions/**/rollout-*.jsonl")
# Only Codex runs started by this Claude session (after it began) count.
SESSION_START = "2026-10-01T11:50:00Z"
OUT = os.path.join(HERE, "USAGE_LOG.md")
TITLE = "Red Light, Blue Light"
CWD_FILTER = ""


def read_jsonl(path):
	with open(path) as handle:
		for line in handle:
			line = line.strip()
			if line:
				try:
					yield json.loads(line)
				except json.JSONDecodeError:
					pass


def claude_usage():
	totals = Counter()
	tools = Counter()
	seen = set()
	turns = 0
	first = last = None
	for row in read_jsonl(CLAUDE_LOG):
		stamp = row.get("timestamp")
		if stamp:
			first = first or stamp
			last = stamp
		if row.get("type") == "user" and isinstance(row.get("message", {}).get("content"), str):
			turns += 1
		msg = row.get("message") or {}
		if msg.get("role") != "assistant":
			continue
		for block in msg.get("content") or []:
			if isinstance(block, dict) and block.get("type") == "tool_use":
				tools[block.get("name", "?")] += 1
		# Streaming writes several rows per API message; count each message id once.
		if msg.get("id") in seen or "usage" not in msg:
			continue
		seen.add(msg.get("id"))
		usage = msg["usage"]
		for key in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens"):
			totals[key] += usage.get(key) or 0
	return totals, tools, len(seen), turns, first, last


def codex_runs():
	runs = []
	for path in sorted(glob.glob(CODEX_GLOB, recursive=True)):
		rows = list(read_jsonl(path))
		if not rows or rows[0].get("timestamp", "") < SESSION_START:
			continue
		final = None
		commands = 0
		meta = {}
		for row in rows:
			payload = row.get("payload") or {}
			if row.get("type") == "session_meta":
				meta = payload
			if payload.get("type") == "token_count" and payload.get("info"):
				final = payload
			if payload.get("type") in ("function_call", "local_shell_call", "custom_tool_call"):
				commands += 1
		if CWD_FILTER and CWD_FILTER not in meta.get("cwd", ""):
			continue
		runs.append({
			"file": os.path.basename(path),
			"start": rows[0].get("timestamp"),
			"end": rows[-1].get("timestamp"),
			"cwd": meta.get("cwd", "?"),
			"model": meta.get("model") or meta.get("model_provider", "?"),
			"usage": (final or {}).get("info", {}).get("total_token_usage", {}),
			"limits": (final or {}).get("rate_limits", {}),
			"tool_calls": commands,
		})
	return runs


def fmt(n):
	return f"{int(n):,}"


def main():
	global CLAUDE_SESSION, CLAUDE_LOG, SESSION_START, OUT, TITLE, CWD_FILTER
	parser = argparse.ArgumentParser()
	parser.add_argument("--session", default=CLAUDE_SESSION)
	parser.add_argument("--since", default=SESSION_START)
	parser.add_argument("--cwd", default="", help="only count Codex runs whose cwd contains this")
	parser.add_argument("--title", default=TITLE)
	parser.add_argument("--out", default=OUT)
	args = parser.parse_args()
	CLAUDE_SESSION, SESSION_START, TITLE, CWD_FILTER = args.session, args.since, args.title, args.cwd
	CLAUDE_LOG = os.path.expanduser(f"~/.claude/projects/-Users-andytran-Coding-Godot/{CLAUDE_SESSION}.jsonl")
	OUT = args.out if os.path.isabs(args.out) else os.path.join(HERE, args.out)
	c_tot, c_tools, c_calls, c_turns, c_first, c_last = claude_usage()
	runs = codex_runs()
	lines = [
		f"# Usage log: {TITLE} build",
		"",
		f"Generated {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')} by `usage/usage_report.py` from local session logs.",
		"",
		"## Claude Code (orchestrator / reviewer)",
		"",
		f"- Session `{CLAUDE_SESSION}`, model claude-opus-5-5",
		f"- Window: {c_first} to {c_last}",
		f"- User prompts: {c_turns} · API calls: {c_calls} · tool calls: {sum(c_tools.values())}",
		"",
		"| Tokens | Count |",
		"| --- | ---: |",
		f"| Input (uncached) | {fmt(c_tot['input_tokens'])} |",
		f"| Cache write | {fmt(c_tot['cache_creation_input_tokens'])} |",
		f"| Cache read | {fmt(c_tot['cache_read_input_tokens'])} |",
		f"| Output | {fmt(c_tot['output_tokens'])} |",
		f"| **Total** | **{fmt(sum(c_tot.values()))}** |",
		"",
		"Tool calls by tool: " + ", ".join(f"{name} x{count}" for name, count in c_tools.most_common()),
		"",
		"## Codex (bulk implementation)",
		"",
		f"Runs (tasks) started from this session: **{len(runs)}**",
		"",
		"| # | Started | Ended | Tool calls | Input | Cached input | Output | Reasoning | Total |",
		"| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
	]
	grand = Counter()
	for index, run in enumerate(runs, 1):
		usage = run["usage"]
		for key in ("input_tokens", "cached_input_tokens", "output_tokens", "reasoning_output_tokens", "total_tokens"):
			grand[key] += usage.get(key, 0)
		lines.append(
			f"| {index} | {run['start']} | {run['end']} | {run['tool_calls']} | {fmt(usage.get('input_tokens', 0))} | "
			f"{fmt(usage.get('cached_input_tokens', 0))} | {fmt(usage.get('output_tokens', 0))} | "
			f"{fmt(usage.get('reasoning_output_tokens', 0))} | {fmt(usage.get('total_tokens', 0))} |")
	lines += [
		f"| | | **All runs** | | {fmt(grand['input_tokens'])} | {fmt(grand['cached_input_tokens'])} | "
		f"{fmt(grand['output_tokens'])} | {fmt(grand['reasoning_output_tokens'])} | **{fmt(grand['total_tokens'])}** |",
		"",
		"Codex `input_tokens` already includes `cached_input_tokens`.",
	]
	if runs and runs[-1]["limits"].get("primary"):
		primary = runs[-1]["limits"]["primary"]
		lines.append(f"Codex plan ({runs[-1]['limits'].get('plan_type', '?')}): weekly window {primary.get('used_percent')}% used at last report.")
	lines += [
		"",
		"## Combined",
		"",
		f"- Claude total tokens: {fmt(sum(c_tot.values()))}",
		f"- Codex total tokens: {fmt(grand['total_tokens'])}",
		f"- **Grand total: {fmt(sum(c_tot.values()) + grand['total_tokens'])}**",
		"",
		"Cached/cache-read tokens are counted in totals but are billed or rate-limited far below fresh tokens.",
		"",
	]
	with open(OUT, "w") as handle:
		handle.write("\n".join(lines))
	print(OUT)


if __name__ == "__main__":
	main()
