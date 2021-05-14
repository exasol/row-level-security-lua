#!/bin/bash

# This script finds and runs Lua unit tests, collects coverage and runs static code analysis.

readonly script_dir=$(dirname "$(readlink -f "$0")")
if [[ -v $1 ]]
then
    readonly base_dir="$1"
else
    readonly base_dir=$(readlink -f "$script_dir/..")
fi

readonly exit_ok=0
readonly exit_software=2
readonly src_module_path="$base_dir/src/main/lua"
readonly test_module_path="$base_dir/src/test/lua"
readonly target_dir="$base_dir/target"
readonly reports_dir="$target_dir/luaunit-reports"
readonly luacov_dir="$target_dir/luacov-reports"

function create_target_directories {
    mkdir -p "$reports_dir"
    mkdir -p "$luacov_dir"
}

##
# Run the unit tests and collect code coverage.
#
# Returns error status in case there were failures.
#
function run_tests {
    cd "$test_module_path"
    readonly tests="$(find . -name '*.lua')"
    test_suites=0
    failures=0
    successes=0
    for testcase in $tests
    do
        ((test_suites++))
        testname=$(echo "$testcase" | sed -e s'/.\///' -e s'/\//./g' -e s'/.lua$//')
        LUA_PATH="$src_module_path/?.lua;$(luarocks path --lr-path)" lua -lluacov "$testcase" -o junit -n "$reports_dir/$testname"
        if [[ "$?" -eq 0 ]]
        then
            ((successes++))
        else
            ((failures++))
        fi
        echo
    done
    echo "Ran $test_suites test suites. $successes successes, $failures failures."
    if [[ "$failed_tests" -eq 0 ]]
    then
        return "$exit_ok"
    else
        return "$exit_software"
    fi
}

##
# Collect the coverage results into a single file.
#
# Returns exit status of coverage collector.
#
function collect_coverage_results {
    echo
    echo "Collecting code coverage results"
    luacov --config "$base_dir/.coverage_config.lua"
    return "$?"
}

##
# Move the coverage results into the target directory.
#
# Returns exit status of `mv` command.
#
function move_coverage_results {
    echo "Moving coverage results to $luacov_dir"
    mv "$test_module_path"/luacov.*.out "$luacov_dir"
    return "$?"
}

function print_coverage_summary {
    echo
    grep --after 500 'File\s*Hits' "$luacov_dir/luacov.report.out"
}

##
# Analyze the Lua code with "luacheck".
#
# Returns exit status of code coverage.
#
function run_static_code_analysis {
    echo
    echo "Running static code analysis"
    echo
    luacheck "$src_module_path" "$test_module_path" --codes --ignore 111 --ignore 112
    return "$?"
}

create_target_directories
run_tests \
&& collect_coverage_results \
&& move_coverage_results \
&& print_coverage_summary \
&& run_static_code_analysis \
|| exit "$exit_software"

exit "$exit_ok"