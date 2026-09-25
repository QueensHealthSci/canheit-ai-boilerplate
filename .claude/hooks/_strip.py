"""Drop heredoc bodies — and, unless --keep-quotes, the contents of quoted strings — from
a shell command.

Used by the guards so that a commit message or echo that merely mentions a forbidden
command is not mistaken for running it. Text after a heredoc terminator is kept, so a real
command following a heredoc is still seen. The rm rule passes --keep-quotes because a
quoted path is a real argument there. guard-secrets does not use this for its verb-plus-path
rule: a quoted path there is a real read.

FAILS CLOSED. If a heredoc opener never meets its terminator — which happens when the `<<`
was itself inside a quoted string — everything after it would otherwise be discarded, and a
guard would see a truncated command. Rather than hand back a command with its tail missing,
this returns the input unchanged so the guards match against the raw text. A false block is
recoverable; a false allow is not.
"""
import re
import sys

keep_quotes = "--keep-quotes" in sys.argv[1:]
src = sys.stdin.read()

out, skip = [], None
for line in src.split("\n"):
    if skip is not None:
        if line.strip() == skip:
            skip = None
        continue
    m = re.search(r"<<-?\s*[\x27\"]?([A-Za-z_][A-Za-z0-9_]*)[\x27\"]?", line)
    if m:
        skip = m.group(1)
    out.append(line)

if skip is not None:
    # Unterminated heredoc: the opener was almost certainly inside a quoted string, so the
    # "body" we dropped is real command text. Hand back the original and let the guards
    # match on it.
    sys.stdout.write(src)
    sys.exit(0)

s = "\n".join(out)
if not keep_quotes:
    s = re.sub(r"\"(?:[^\"\\]|\\.)*\"", "\"\"", s)
    s = re.sub(r"\x27[^\x27]*\x27", "\x27\x27", s)
sys.stdout.write(s)
