#!/usr/bin/env bash
set -euo pipefail

TWITTER_TOKEN="${TWITTER_TOKEN:-}"

OUT_DIR="output"
mkdir -p "$OUT_DIR"

WINDOW_HOURS=6

SINCE_DATE=$(date -u -d "yesterday" +"%Y-%m-%d")
UNTIL_DATE=$(date -u +"%Y-%m-%d")

echo "Crawl day: since ${SINCE_DATE}, until ${UNTIL_DATE}"

i=0
out_files=()

while true; do
  window_start=$(date -u -d "${SINCE_DATE} +${i} hours" +"%Y-%m-%dT%H:%M:%SZ")
  window_end=$(date -u -d "${window_start} +${WINDOW_HOURS} hours" +"%Y-%m-%dT%H:%M:%SZ")

  if [[ "$(date -u -d "$window_start" +%s)" -ge "$(date -u -d "${UNTIL_DATE}T00:00:00Z" +%s)" ]]; then
    break
  fi

  fname="${OUT_DIR}/tweets_${SINCE_DATE}_w${i}.csv"

  echo "Fetching window ${window_start} -> ${window_end}"

  SEARCH='pemilu OR jokowi OR prabowo OR capres OR pilpres'
  QUERY="${SEARCH} since:${window_start} until:${window_end} lang:id"

  npx -y tweet-harvest@2.6.1 \
    -o "${fname}" \
    -s "${QUERY}" \
    --tab "LATEST" \
    -l 1000 \
    --token "${TWITTER_TOKEN}"

  out_files+=("${fname}")
  i=$((i + WINDOW_HOURS))
done

FINAL="${OUT_DIR}/pemilu_${SINCE_DATE}.csv"
first=true
> "$FINAL"

for f in "${out_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    continue
  fi

  if $first; then
    cat "$f" >> "$FINAL"
    first=false
  else
    tail -n +2 "$f" >> "$FINAL"
  fi
done

echo "Final file: $FINAL"
ls -lh "$OUT_DIR"
