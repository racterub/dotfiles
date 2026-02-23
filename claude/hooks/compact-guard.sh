#!/bin/bash
# PreCompact hook: block auto-compaction, let user decide
# Matcher: auto (manual /compact passes through)

echo "Auto-compaction blocked by hook. Ask the user if they want to run /compact manually." >&2
exit 2
