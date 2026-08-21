#!/bin/sh
# check-theme-drift.sh — verifies .planning/sketches/themes/default.css's
# color variables stay in sync with assets/css/app.css's daisyUI light/dark
# theme blocks (the single upstream source of the PukllayClub brand
# palette). Also checks that default.css's two dark regions (the
# prefers-color-scheme media query and the explicit data-theme selector)
# agree with each other.
#
# Usage: .planning/sketches/themes/check-theme-drift.sh
#
# Exits 0 if every mapped colour pair matches (case-insensitive hex
# compare) and both dark regions agree with each other. Exits 1 on any
# drift. Only colour tokens are checked — typography, spacing, radius,
# shadow and motion tokens have no daisyUI counterpart and are sketch-only
# (the motion values in particular are sketch 006's validated winner).

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)
APP_CSS="$ROOT_DIR/assets/css/app.css"
DEFAULT_CSS="$ROOT_DIR/.planning/sketches/themes/default.css"

# extract_block FILE PATTERN
# Prints the lines from the first line matching PATTERN through the next
# line that is a closing brace at column 0 (inclusive of both ends).
extract_block() {
  awk -v pat="$2" '
    $0 ~ pat { found = 1 }
    found { print }
    found && /^}/ { exit }
  ' "$1"
}

# value_of BLOCK_FILE PROPERTY
# Prints the hex value of a `--custom-property: value;` declaration inside
# a block file produced by extract_block. The trailing colon in the search
# pattern disambiguates e.g. --color-accent from --color-accent-content.
value_of() {
  grep -m1 -- "$2:" "$1" 2>/dev/null \
    | sed -E 's/^[^:]*:[[:space:]]*([^;]+);.*/\1/' \
    | tr -d '[:space:]'
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

extract_block "$APP_CSS" 'name: "light";' >"$TMP/app-light"
extract_block "$APP_CSS" 'name: "dark";' >"$TMP/app-dark"
extract_block "$DEFAULT_CSS" '^:root \{' >"$TMP/sketch-light"
extract_block "$DEFAULT_CSS" '^@media \(prefers-color-scheme: dark\)' >"$TMP/sketch-dark-media"
extract_block "$DEFAULT_CSS" '^:root\[data-theme="dark"\]' >"$TMP/sketch-dark-explicit"

DRIFT=0

check_pair() {
  # $1=label $2=upstream_prop $3=upstream_block $4=sketch_prop $5=sketch_block
  upstream_val=$(value_of "$3" "$2")
  sketch_val=$(value_of "$5" "$4")
  if [ "$(lower "$upstream_val")" = "$(lower "$sketch_val")" ]; then
    echo "$1 OK ($upstream_val)"
  else
    echo "$1 DRIFT upstream=$upstream_val sketch=$sketch_val"
    DRIFT=1
  fi
}

# The 13 mapped pairs (see default.css's own header for the full table).
# --color-base-300 intentionally feeds two sketch variables.
run_pairs() {
  region="$1" upstream_block="$2" sketch_block="$3"
  check_pair "$region base-100->bg" "--color-base-100" "$upstream_block" "--color-bg" "$sketch_block"
  check_pair "$region base-200->surface" "--color-base-200" "$upstream_block" "--color-surface" "$sketch_block"
  check_pair "$region base-300->surface-2" "--color-base-300" "$upstream_block" "--color-surface-2" "$sketch_block"
  check_pair "$region base-300->border" "--color-base-300" "$upstream_block" "--color-border" "$sketch_block"
  check_pair "$region base-content->text" "--color-base-content" "$upstream_block" "--color-text" "$sketch_block"
  check_pair "$region neutral->text-muted" "--color-neutral" "$upstream_block" "--color-text-muted" "$sketch_block"
  check_pair "$region primary->primary" "--color-primary" "$upstream_block" "--color-primary" "$sketch_block"
  check_pair "$region primary-content->primary-content" "--color-primary-content" "$upstream_block" "--color-primary-content" "$sketch_block"
  check_pair "$region secondary->secondary" "--color-secondary" "$upstream_block" "--color-secondary" "$sketch_block"
  check_pair "$region accent->accent-bg" "--color-accent" "$upstream_block" "--color-accent-bg" "$sketch_block"
  check_pair "$region accent-content->accent-text" "--color-accent-content" "$upstream_block" "--color-accent-text" "$sketch_block"
  check_pair "$region error->danger" "--color-error" "$upstream_block" "--color-danger" "$sketch_block"
  check_pair "$region success->success" "--color-success" "$upstream_block" "--color-success" "$sketch_block"
}

echo "== light =="
run_pairs "light" "$TMP/app-light" "$TMP/sketch-light"

echo "== dark (media-query region) =="
run_pairs "dark" "$TMP/app-dark" "$TMP/sketch-dark-media"

echo "== dark regions agreement (media-query vs explicit data-theme) =="
for prop in --color-bg --color-surface --color-surface-2 --color-text --color-text-muted \
  --color-primary --color-primary-content --color-secondary --color-accent-bg \
  --color-accent-text --color-border --color-danger --color-success; do
  media_val=$(value_of "$TMP/sketch-dark-media" "$prop")
  explicit_val=$(value_of "$TMP/sketch-dark-explicit" "$prop")
  if [ "$(lower "$media_val")" = "$(lower "$explicit_val")" ]; then
    echo "dark-regions $prop OK ($media_val)"
  else
    echo "dark-regions $prop DRIFT media=$media_val explicit=$explicit_val"
    DRIFT=1
  fi
done

exit $DRIFT
