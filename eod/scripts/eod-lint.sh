#!/usr/bin/env bash
set -euo pipefail

allow_discord=false
input_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --allow-discord)
      allow_discord=true
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: eod-lint.sh [--allow-discord] [report.txt]

Validates the EOD report shape. Reads stdin when report.txt is omitted.
USAGE
      exit 0
      ;;
    *)
      if [ -n "$input_file" ]; then
        printf 'error: unexpected argument: %s\n' "$1" >&2
        exit 2
      fi
      input_file="$1"
      ;;
  esac
  shift
done

raw="$(mktemp)"
report="$(mktemp)"
stripped="$(mktemp)"
trap 'rm -f "$raw" "$report" "$stripped"' EXIT

if [ -n "$input_file" ]; then
  cat "$input_file" > "$raw"
else
  cat > "$raw"
fi

cp "$raw" "$report"

first_line="$(sed -n '1p' "$report")"
if [[ "$first_line" =~ ^\`\`\`(txt)?[[:space:]]*$ ]]; then
  tail -n +2 "$report" > "$stripped"
  mv "$stripped" "$report"
  stripped="$(mktemp)"
fi

last_line="$(tail -n 1 "$report" 2>/dev/null || true)"
if [[ "$last_line" =~ ^\`\`\`[[:space:]]*$ ]]; then
  sed '$d' "$report" > "$stripped"
  mv "$stripped" "$report"
  stripped="$(mktemp)"
fi

fail() {
  printf 'eod lint failed: %s\n' "$1" >&2
  exit 1
}

count_heading() {
  pattern="$1"
  grep -cx "$pattern" "$report" 2>/dev/null || true
}

line_for_heading() {
  pattern="$1"
  grep -nx "$pattern" "$report" 2>/dev/null | cut -d: -f1
}

[ -s "$report" ] || fail "empty report"

[ "$(count_heading 'done:')" = "1" ] || fail "expected exactly one done: heading"
[ "$(count_heading 'tomorrow')" = "1" ] || fail "expected exactly one tomorrow heading"
[ "$(count_heading 'ai:')" = "1" ] || fail "expected exactly one ai: heading"

done_line="$(line_for_heading 'done:')"
tomorrow_line="$(line_for_heading 'tomorrow')"
ai_line="$(line_for_heading 'ai:')"

[ "$done_line" -lt "$tomorrow_line" ] || fail "done: must appear before tomorrow"
[ "$tomorrow_line" -lt "$ai_line" ] || fail "tomorrow must appear before ai:"

date_line="$(awk 'NF { print NR; exit }' "$report")"
[ "$date_line" = "1" ] || fail "first non-empty line must be the date"

done_body_line=$((done_line + 1))
done_body="$(sed -n "${done_body_line}p" "$report")"
[ -n "$done_body" ] || fail "done: must be followed by one paragraph"
[ "$done_body" != "tomorrow" ] || fail "done: paragraph is missing"

if [ $((done_line + 2)) -le $((tomorrow_line - 1)) ] && sed -n "$((done_line + 2)),$((tomorrow_line - 1))p" "$report" | grep -q '[^[:space:]]'; then
  fail "done: must be one paragraph with no blank-separated extra body"
fi

tomorrow_items="$(sed -n "$((tomorrow_line + 1)),$((ai_line - 1))p" "$report" | grep -c '^- ' 2>/dev/null || true)"
[ "$tomorrow_items" -ge 1 ] || fail "tomorrow must include at least one dash-prefixed item"

if grep -nix 'blockers:' "$report" >/dev/null 2>&1; then
  fail "do not include a blockers: section"
fi

em_dash="$(printf '\342\200\224')"
en_dash="$(printf '\342\200\223')"
if LC_ALL=C grep -q "$em_dash" "$report" || LC_ALL=C grep -q "$en_dash" "$report"; then
  fail "use plain hyphens, not dash punctuation"
fi

ai_news_line=$((ai_line + 1))
ai_source_line=$((ai_line + 2))
ai_news="$(sed -n "${ai_news_line}p" "$report")"
ai_source="$(sed -n "${ai_source_line}p" "$report")"

[ -n "$ai_news" ] || fail "ai: must be followed by one news sentence"
printf '%s\n' "$ai_source" | grep -Eq '^https?://[^[:space:]]+$' || fail "ai source must be one bare URL on the line after the news"

if printf '%s\n' "$ai_source" | grep -Eq '^\[[^]]+\]\(https?://'; then
  fail "ai source must not be wrapped as a Markdown link"
fi

extra_ai_lines="$(sed -n "$((ai_line + 3)),\$p" "$report" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
[ "$extra_ai_lines" = "0" ] || fail "ai: section must contain only news sentence and source URL"

url_errors="$(AI_SOURCE_LINE="$ai_source_line" perl -0ne '
  my $ai_source_line = $ENV{AI_SOURCE_LINE};
  my $line_no = 0;
  my @bad;
  for my $line (split /\n/, $_, -1) {
    $line_no++;
    while ($line =~ m{https?://\S+}g) {
      my $start = $-[0];
      my $prev = $start > 0 ? substr($line, $start - 1, 1) : "";
      if ($line_no == $ai_source_line && $line =~ m{^\s*https?://\S+\s*$}) {
        next;
      }
      next if $prev eq "(";
      push @bad, "line $line_no: bare URL must be masked unless it is the AI source line";
    }
  }
  print join("\n", @bad);
' "$report")"

[ -z "$url_errors" ] || fail "$url_errors"

if [ "$allow_discord" = false ] && grep -ni 'discord' "$report" >/dev/null 2>&1; then
  fail "discord is mentioned without --allow-discord"
fi

printf 'eod lint ok\n'
