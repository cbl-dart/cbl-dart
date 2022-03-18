#!/usr/bin/env bash

set -e

# === Globals =================================================================

crashReportName="crash-report.txt"

# === Usage ===================================================================

function usage() {
    cat <<-EOF
SYNOPSYS
    -e EXECUTALBE -c CORE-DUMP -o OUTPUT-DIRECTORY
        creates a crash report for an executable given a core dump

DESCRIPTION
    -e EXECUTALBE
        executeable which crashed

    -c CORE-DUMP
        core dump of the crashed process

    -o OUTPUT-DIRECTORY
        directory to store output in
EOF
}

function usageFailure {
    usage
    exit 1
}

function requireOption() {
    if [[ -z "$3" ]]; then
        echo "$2 ($1) is required and was not provided"
        echo
        usageFailure
    fi
}

# === Implementation ==========================================================

executable=""
coreDump=""
outputDirectory=""

while getopts "e:c:o:" optName; do
    case "$optName" in
    e)
        executable="$OPTARG"
        ;;
    c)
        coreDump="$OPTARG"
        ;;
    o)
        outputDirectory="$OPTARG"
        ;;
    ?)
        usageFailure
        ;;
    esac
done

requireOption -e EXECUTALBE "$executable"
requireOption -c CORE-DUMP "$coreDump"
requireOption -o OUTPUT-DIRECTORY "$outputDirectory"

crashReport="$outputDirectory/$crashReportName"

function installGdb() {
    if ! which gdb >/dev/null; then
        echo "Installing gdb.."
        sudo apt-get update
        sudo apt-get install gdb
    fi
}

function checkCoreDump() {
    # Wait a few seconds befor checking for core dump
    sleep 5

    if [ ! -e "$coreDump" ]; then
        echo "Not generating report: Could not find core dump"
        echo "Directory has these contents"
        ls -alh "$(dirname "$coreDump")"
        exit 0
    else
        echo "Found core dump:"
        ls -lh "$coreDump"

        echo "Waiting until core dump is complete..."
        while lsof | grep "$(realpath "$coreDump")" >/dev/null; do
            sleep 5
        done
        echo "Core dump is complete"
    fi
}

function createCrashReportFile() {
    echo "Creating crash report..."
    mkdir -p "$outputDirectory"
    touch "$crashReport"
}

function writeThreadBacktraces() {
    echo "Adding backtraces of all threads..."
    gdb \
        -batch \
        -ex 'thread apply all bt' \
        "$executable" "$coreDump" \
        >"$crashReport"
}

echo "Creating crash report..."

checkCoreDump
installGdb
createCrashReportFile
writeThreadBacktraces

echo "Created crash report"
