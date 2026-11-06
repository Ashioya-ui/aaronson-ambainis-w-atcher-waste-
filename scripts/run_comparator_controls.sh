#!/bin/sh
# The controls of the comparator run: five small runs on the project `verification/control/`,
# one that comparator must accept and four that it must reject.
#
#   accept                           a true theorem with an honest proof
#   reject-other-statement           the solution proves another statement than the challenge
#   reject-axiom                     the solution uses an axiom that is not permitted
#   reject-false-proof               the solution rests on a constant of type `False` that was
#                                    added while the kernel was switched off
#   reject-false-proof-lean-kernel   the same without nanoda: the Lean kernel alone must reject
#
# Usage: run_comparator_controls.sh [--unsandboxed]
# Without the option each run is sandboxed (run_comparator.sh, Linux only); with it the runs
# go through run_comparator_unsandboxed.sh. Exit status 0 exactly if all five runs end as
# they must. A run counts as accepted if its exit status is 0 and its output has the line
# `Your solution is okay!`. A run that must be rejected must also be rejected for its own
# reason: the output must contain the message that comparator (at the revision of
# `comparator/PINS.env`) prints for that reason. A run that stops for another reason, such
# as a missing tool, is reported as wrong.

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runner="$root/scripts/run_comparator.sh"
if [ "${1:-}" = "--unsandboxed" ]; then
  runner="$root/scripts/run_comparator_unsandboxed.sh"
fi

project="$root/verification/control"
out=$(mktemp)
clean=$(mktemp)
trap 'rm -f -- "$out" "$clean"' EXIT HUP INT TERM

failures=0
for name in accept reject-other-statement reject-axiom reject-false-proof \
            reject-false-proof-lean-kernel; do
  status=0
  "$runner" "$project" "comparator/$name.json" >"$out" 2>&1 || status=$?
  tr -d '\r' <"$out" >"$clean"

  # What must happen, the message that shows it, and how many lines follow that message.
  case "$name" in
    accept)
      expected=accepted; reason='Your solution is okay!'; after=0 ;;
    reject-other-statement)
      expected=rejected; reason='Challenge and solution theorem statement do not match'; after=0 ;;
    reject-axiom)
      expected=rejected; reason='Illegal axiom detected'; after=0 ;;
    reject-false-proof)
      expected=rejected; reason='Child exited with'; after=0 ;;
    reject-false-proof-lean-kernel)
      expected=rejected; reason='(kernel) declaration type mismatch'; after=3 ;;
  esac

  if [ "$status" -eq 0 ] && grep -q -x 'Your solution is okay!' "$clean"; then
    verdict=accepted
  else
    verdict=rejected
  fi

  if [ "$name" = reject-false-proof ]; then
    # The child that fails must be nanoda: the failure comes after nanoda was started, and
    # nanoda does not accept.
    if awk '/Running nanoda kernel on solution/ { started = 1 }
            /Nanoda kernel accepts the solution/ { accepted = 1 }
            started && /Child exited with/ { failed = 1 }
            END { exit (failed && !accepted) ? 0 : 1 }' "$clean"; then
      found=yes
    else
      found=no
    fi
  elif grep -q -F -e "$reason" "$clean"; then
    found=yes
  else
    found=no
  fi

  if [ "$verdict" = "$expected" ] && [ "$found" = yes ]; then
    mark="as it must be"
  elif [ "$verdict" = "$expected" ]; then
    if [ "$name" = reject-false-proof ]; then
      mark="WRONG: no failure of nanoda after the line 'Running nanoda kernel on solution'"
    else
      mark="WRONG: the expected message is missing: $reason"
    fi
    failures=$((failures + 1))
  else
    mark="WRONG: must be $expected"
    failures=$((failures + 1))
  fi
  echo "comparator control: $name: $verdict (exit status $status), $mark"
  if [ "$found" = yes ]; then
    if [ "$name" = reject-false-proof ]; then
      grep -F -e 'Running nanoda kernel on solution' -e "$reason" "$clean" | sed 's/^/    | /'
    else
      grep -F -m 1 -A "$after" -e "$reason" "$clean" | sed 's/^/    | /'
    fi
  else
    grep -v -e '^fake_landrun.sh:' -e '^run_comparator' -e '^check_sandbox.sh:' "$clean" \
      | tail -n 12 | sed 's/^/    | /'
  fi
done

if [ "$failures" -eq 0 ]; then
  echo "comparator controls: all five runs ended as they must"
else
  echo "comparator controls: $failures of five runs ended WRONGLY"
  exit 1
fi
