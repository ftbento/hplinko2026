#!/usr/bin/env bash
# Generates N passwords in the format word-word-word from words.txt

set -euo pipefail

WORDS_FILE="${WORDS_FILE:-$(dirname "$0")/words.txt}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <count> [words_file]" >&2
    exit 1
fi

COUNT="$1"
[ $# -ge 2 ] && WORDS_FILE="$2"

if [ ! -f "$WORDS_FILE" ]; then
    echo "Error: word list '$WORDS_FILE' not found." >&2
    exit 1
fi

mapfile -t WORDS < <(grep -v '^[[:space:]]*$' "$WORDS_FILE")
TOTAL=${#WORDS[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "Error: word list is empty." >&2
    exit 1
fi

# Unbiased random indices via shuf (avoids $RANDOM modulo bias)
mapfile -t PICKS < <(shuf -i 0-$((TOTAL - 1)) -r -n $((COUNT * 3)))

for ((i = 0; i < COUNT; i++)); do
    printf '%s-%s-%s\n' \
        "${WORDS[${PICKS[$((i * 3))]}]}" \
        "${WORDS[${PICKS[$((i * 3 + 1))]}]}" \
        "${WORDS[${PICKS[$((i * 3 + 2))]}]}"
done
