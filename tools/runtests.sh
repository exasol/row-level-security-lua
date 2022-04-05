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
readonly src_exasolrls_path="$src_module_path/exasolrls"
readonly src_exasolvs_path="$src_module_path/exasolvs"
readonly src_administration_path="$src_module_path/administration"
readonly test_module_path="$base_dir/spec"
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
# Return error status in case there were failures.
#
function run_tests {
    cd "$base_dir" || exit
    busted -c
}

##
# Collect the coverage results into a single file.
#
# Return exit status of coverage collector.
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
# Return exit status of `mv` command.
#
function move_coverage_results {
    echo "Moving coverage results to $luacov_dir"
    mv "$base_dir"/luacov.*.out "$luacov_dir"
    return "$?"
}

##
# Print the summary section of the code coverage report to the console
#
function print_coverage_summary {
    echo
    grep --after 500 'File\s*Hits' "$luacov_dir/luacov.report.out"
}

##
# Analyze the Lua code with "luacheck".
#
# Return exit status of code coverage.
#
function run_static_code_analysis {
    echo
    echo "Running static code analysis"
    echo
    luacheck "$src_exasolrls_path" "$test_module_path" --codes --ignore 111 --ignore 112 --ignore 212
    luacheck "$src_administration_path" --codes --ignore 111 --ignore 112 --ignore 113
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