#!/bin/sh
# papercut — append a one-line friction note to PAPERCUTS.md at the workspace root.
#
#   papercut -m <model> "doing X -> Y got in the way (guess at cause/fix)"
#   echo "message" | papercut -m <model>
#
# Root = git toplevel, else cwd. If that is / or $HOME (no real project),
# falls back to ${XDG_STATE_HOME:-~/.local/state}/papercuts/PAPERCUTS.md.
# PAPERCUTS_FILE overrides the target; PAPERCUT_MODEL sets a default model.

set -eu

usage() {
  cat <<'EOF'
Usage: papercut [-m|--model MODEL] [--] MESSAGE...
       echo MESSAGE | papercut [-m MODEL]

Appends "- YYYY-MM-DD [MODEL] MESSAGE" to PAPERCUTS.md at the git root
(or the current directory outside git), creating it with a "# Papercuts"
header if needed.

Options:
  -m, --model MODEL   Model/agent that hit the friction (default: $PAPERCUT_MODEL or "unknown")
  -p, --path          Print the target file path and exit
  -h, --help          Show this help

Env:
  PAPERCUTS_FILE      Explicit target file (skips root detection)
  PAPERCUT_MODEL      Default model name
EOF
}

die() { printf 'papercut: %s\n' "$1" >&2; exit 2; }

model=${PAPERCUT_MODEL:-unknown}
print_path=0

while [ $# -gt 0 ]; do
  case $1 in
    -m|--model) [ $# -ge 2 ] || die "$1 needs a value"; model=$2; shift 2 ;;
    --model=*)  model=${1#--model=}; shift ;;
    -p|--path)  print_path=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    --)         shift; break ;;
    -?*)        die "unknown option: $1 (see --help)" ;;
    *)          break ;;
  esac
done

if [ -n "${PAPERCUTS_FILE:-}" ]; then
  file=$PAPERCUTS_FILE
else
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$(pwd)
  case $root in
    /|"$HOME") root=${XDG_STATE_HOME:-$HOME/.local/state}/papercuts; mkdir -p "$root" ;;
  esac
  file=$root/PAPERCUTS.md
fi

if [ "$print_path" -eq 1 ]; then
  printf '%s\n' "$file"
  exit 0
fi

if [ $# -gt 0 ]; then
  msg=$*
elif [ ! -t 0 ]; then
  msg=$(cat)
else
  usage >&2; exit 2
fi

# One entry per line: fold newlines/tabs into spaces, squeeze, trim.
msg=$(printf '%s' "$msg" | tr '\r\n\t' '   ' | tr -s ' ' | sed 's/^ //; s/ $//')
model=$(printf '%s' "$model" | tr -d '[]\r\n')
[ -n "$msg" ] || die "empty message"

# Create the file only if it's missing (noclobber), so agents writing at the same time can't add the header twice.
( set -C; printf '# Papercuts\n\n' > "$file" ) 2>/dev/null || true

# Make sure the existing file ends in a newline before appending.
if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
  printf '\n' >> "$file"
fi

entry="- $(date +%Y-%m-%d) [$model] $msg"
printf '%s\n' "$entry" >> "$file"
printf 'papercut: %s\n  -> %s\n' "$entry" "$file"
