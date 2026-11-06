#!/bin/sh
# Does `landrun` confine a process on this machine?
#
# Comparator calls `landrun` with the flag `--best-effort`. With that flag landrun does not
# stop when the kernel offers no Landlock, or less of it than asked for: it runs the command
# with whatever confinement is left, possibly none. So a run of comparator can end with
# `Your solution is okay!` on a machine where nothing was sandboxed. This script tests the
# sandbox with the flags that comparator uses, by two writes into a fresh directory:
#
#   1. with the directory declared writable, the write must succeed;
#   2. without that declaration, the write must be refused.
#
# Exit status 0 exactly if both hold. The second test is the one that fails on a kernel
# without Landlock. The first shows that a refusal in the second comes from the sandbox.

set -eu

landrun_bin=${LANDRUN_BIN:-landrun}

if ! command -v "$landrun_bin" >/dev/null 2>&1; then
  echo "check_sandbox.sh: missing tool: $landrun_bin" >&2
  exit 2
fi

probe_dir=$(mktemp -d)
trap 'rm -rf -- "$probe_dir"' EXIT HUP INT TERM

status=0

"$landrun_bin" --best-effort --ro / --rw /dev --rw "$probe_dir" -ldd -add-exec \
  sh -c 'echo allowed > "$1/allowed"' probe "$probe_dir" >/dev/null 2>&1 || true
if [ -f "$probe_dir/allowed" ]; then
  echo "check_sandbox.sh: a write to a directory declared writable succeeded (as it must)"
else
  echo "check_sandbox.sh: a write to a directory declared writable FAILED: landrun does not work here"
  status=1
fi

"$landrun_bin" --best-effort --ro / --rw /dev -ldd -add-exec \
  sh -c 'echo denied > "$1/denied"' probe "$probe_dir" >/dev/null 2>&1 || true
if [ -f "$probe_dir/denied" ]; then
  echo "check_sandbox.sh: a write outside the declared directories SUCCEEDED: there is no sandbox here"
  status=1
else
  echo "check_sandbox.sh: a write outside the declared directories was refused (as it must)"
fi

if [ "$status" -eq 0 ]; then
  echo "check_sandbox.sh: the sandbox holds"
else
  echo "check_sandbox.sh: the sandbox does NOT hold; a comparator run on this machine is no certificate"
fi
exit "$status"
