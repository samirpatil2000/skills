#!/bin/bash
# Push a Cog project to Replicate so that it survives the Claude Code memory reaper and WSL idle shutdown.
#   MSYS_NO_PATHCONV=1 wsl -d Ubuntu -u root -- bash /mnt/c/.../push_detached.sh /mnt/d/path/to/project r8.im/owner/model
# Run this script itself as a Claude Code background task: it is only a light watcher. The real push runs
# under setsid/nohup inside WSL, so it keeps going even if the watcher is killed (re-run the script to re-attach:
# it will not start a second push while one is running).
# Log: /root/cog_push_<model>.log (not /tmp: WSL /tmp is tmpfs and is lost on VM restart).
set -u
PROJECT="$1"; TARGET="$2"
LOG="/root/cog_push_$(basename "$TARGET").log"

if ! pgrep -f "^cog push $TARGET" >/dev/null; then
  cd "$PROJECT" || exit 1
  setsid nohup bash -c "cog push $TARGET; echo PUSH-EXIT=\$?" > "$LOG" 2>&1 < /dev/null &
  echo "started push -> $LOG"
else
  echo "push already running -> $LOG"
fi

# Watch: keeps a wsl client attached (WSL stops idle VMs) and drops page cache every ~5 min,
# because the WSL page cache counts as used memory on Windows.
n=0
until grep -q "PUSH-EXIT" "$LOG" 2>/dev/null; do
  sleep 20; n=$((n + 1))
  if [ $((n % 15)) -eq 0 ]; then sync; echo 1 > /proc/sys/vm/drop_caches; fi
done
sync; echo 1 > /proc/sys/vm/drop_caches
sed 's/\x1b\[[0-9;]*m//g' "$LOG" \
  | grep -v -E '^#[0-9]+ |Waiting|Preparing|Pushing|Layer already exists|no access allowed|load .dockerignore' \
  | tail -12
grep -q "PUSH-EXIT=0" "$LOG" && grep -q "digest:" "$LOG" && echo "PUSH OK" || echo "PUSH FAILED - see $LOG and references/errors.md"
