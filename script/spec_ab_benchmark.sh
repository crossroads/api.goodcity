#!/usr/bin/env bash
#
# A/B benchmark for spec-suite speed work (see doc/spec-fixtures-plan.md).
#
# Alternates runs of the same spec files, on a fixed seed, between two checkouts that
# share the test database, so machine drift affects both sides equally. Single
# full-suite wall times locally vary by 5-10% and are not evidence.
#
#   git worktree add --detach ../api-baseline <baseline-sha>
#   script/spec_ab_benchmark.sh ../api-baseline . 2 spec/models/order_spec.rb ...
#
# Before each A (baseline) run the fixtured tables are emptied, so the baseline sees a
# cold database the way CI does rather than finding persisted fixture rows.
set -u

if [ $# -lt 4 ]; then
  echo "usage: $0 <dir A> <dir B> <rounds> <spec paths...>" >&2
  exit 1
fi

A=$1; B=$2; ROUNDS=$3; shift 3
SPECS="$*"
SEED=${SEED:-50161}
FIXTURED_TABLES=$(cd "$B" && ls spec/fixtures/*.yml 2>/dev/null | xargs -n1 basename | sed 's/\.yml$//' | tr '\n' ' ')

run() {
  local round=$1 side=$2 dir=$3
  if [ "$side" = A ] && [ -n "$FIXTURED_TABLES" ]; then
    (cd "$dir" && RAILS_ENV=test bin/rails runner "
      %w[$FIXTURED_TABLES].each { |t| ActiveRecord::Base.connection.execute(\"DELETE FROM #{t}\") }
    " >/dev/null 2>&1)
  fi
  local start end result
  start=$(date +%s.%N)
  result=$(cd "$dir" && bundle exec rspec --seed "$SEED" $SPECS 2>&1 | grep -E "^[0-9]+ examples?,")
  end=$(date +%s.%N)
  printf "%s\t%s\t%6.1fs\t%s\n" "$round" "$side" "$(echo "$end - $start" | bc)" "$result"
}

printf "round\tside\twall\tresult\n"
for round in $(seq 1 "$ROUNDS"); do
  run "$round" A "$A"
  run "$round" B "$B"
done
