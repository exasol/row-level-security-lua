#!/bin/bash

# This script finds and runs Lua unit tests.

readonly script_dir=$(dirname "$(readlink -f "$0")")
if [[ -v $1 ]]
then
    readonly base_dir="$1"
else
    readonly base_dir=$(readlink -f "$script_dir/..")
fi

readonly src_module_path="$base_dir/src/main/lua"
readonly test_module_path="$base_dir/src/test/lua"
readonly target_dir="$base_dir/target"
readonly reports_dir="$target_dir/luaunit_reports"

mkdir -p "$reports_dir"

cd $test_module_path
readonly tests="$(find . -name '*.lua')"

test_suites=0
failures=0
successes=0

for testcase in $tests
do
    ((test_suites++))
    testname=$(echo "$testcase" | sed -e s'/.\///' -e s'/\//./g' -e s'/.lua$//')
    LUA_PATH="$src_module_path/?.lua;$(luarocks path --lr-path)" lua "$testcase" -o junit -n "$reports_dir/$testname"
    if [[ "$?" -eq 0 ]]
    then
        ((successes++))
    else
        ((failures++))
    fi
    echo
done

echo "Ran $test_suites test suites. $successes successes, $failures failures."

if [[ "$failures" -ne 0 ]]
then
    exit -1
else
    exit 0
fi