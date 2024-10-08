#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------------------------
# make_test_batches.sh

# ----------------------------------------------------------------------------------------------------------------------
# Environment Settings
# ----------------------------------------------------------------------------------------------------------------------

# shopt -s

# ----------------------------------------------------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------------------------------------------------

THIS_SCRIPT="${0##*/}"
DIR_NAME="${PWD##*/}"
PARENT_DIR_PATH="${PWD%/*}"
PARENT_DIR_NAME="${PARENT_DIR_PATH##*/}"

RC_LOG="false"
[[ "$RC_LOG" == "true" ]] && LOG_FILE="${THIS_SCRIPT/.sh}.log"
IFS_BAK=$IFS


# ----------------------------------------------------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------------------------------------------------

# This function enables syslog style error code handling with colors.
#   Named loggerx so as to avoid clobbering logger if present.
#   Note: There is no 9th severity level in RFC5424.
function loggerx() {
  [[ $1 -eq 0 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;30;41mEMERGENCY\e[0m: ${*:2}"
  [[ $1 -eq 1 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;31;43mALERT\e[0m: ${*:2}"
  [[ $1 -eq 2 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;97;41mCRITICAL\e[0m: ${*:2}"
  [[ $1 -eq 3 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;31mERROR\e[0m: ${*:2}"
  [[ $1 -eq 4 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;33mWARNING\e[0m: ${*:2}"
  [[ $1 -eq 5 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;30;107mNOTICE\e[0m: ${*:2}"
  [[ $1 -eq 6 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;39mINFO\e[0m: ${*:2}"
  [[ $1 -eq 7 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;97;46mDEBUG\e[0m: ${*:2}"
  [[ $1 -eq 9 ]] && echo -e "$(date --utc +"%FT%T.%3NZ") - \e[01;32mSUCCESS\e[0m: ${*:2}"
}

# Echo Task
function et() { loggerx 5 "TASK START: $task..."; }

# Result Check Handler
#   Implements intermediate logic.
function rc_handler() {
  if [[ $1 -eq $2 ]] ; then
    loggerx 9 "TASK END: $task."
  else
    loggerx 3 "TASK END: $task - exit code $2"
    [[ "$3" == "KILL" ]] && exit "$2"
  fi
}

# Result Check
#  - Checks that the exit code matches the desired exit code.
#  - Optionally Logs
#  - Optionally KILLS
function rc() {
  result=$?
  if [[ "$RC_LOG" == "true" ]]; then
    rc_handler "$1" "$result" | tee -a "$LOG_FILE"
  else
    rc_handler "$1" "$result" "$2"
  fi
}

# Result Check Example
#    task="Some foo work"; et
#    echo foo; false; rc 0 KILL
#    echo foo; rc 0


# ----------------------------------------------------------------------------------------------------------------------
# Help & arguments example
# ----------------------------------------------------------------------------------------------------------------------

show_help() {
echo -e "$(cat << EOF

NAME
    ${0##*/} - Makes Test Batches.

SYNOPSIS
    ${0##*/} [OPTION]

DESCRIPTION
    This tests generates batches of tests under the side_batches dir.

    -u \e[4mURL\e[0m         (REQUIRED)   The Base URL of the tests.
    -t \e[4mTOTAL_TESTS\e[0m (REQUIRED)   The total number of tests.
    -h
        Show this help menu.

EXAMPLES:
      ./${0##*/} -u http://host.docker.internal:8080 -t 100

EOF
)
"
exit 1
}

# ----------------------------------------------------------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------------------------------------------------------

task="MISSING ARGUMENTS!"
[[ $# -eq 4 ]] || rc 0
[[ $# -eq 4 ]] || show_help

OPTIND=1
while getopts "hu:t:" opt; do
  case $opt in
    h)
      show_help
      ;;
    u)
      BASE_URL="$OPTARG"
      BASE_URL="${BASE_URL//\//\\/}"
      ;;
    t)
      TOTAL_TESTS="$OPTARG"
      ;;
    *)
      echo "ERROR: Invalid argument.!"
      show_help
      ;;
  esac
done
shift $((OPTIND-1))


# ----------------------------------------------------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------------------------------------------------

function genpass_alnum() {
    [[ $1 -gt 128 ]] && echo "ERROR: int must be <= 128, if supplied." && return 1;
    len=$1;
    if [[ -z $1 ]]; then
        openssl rand -base64 128 | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1;
    else
        openssl rand -base64 128 | tr -dc 'a-zA-Z0-9' | fold -w $((len)) | head -n 1;
    fi
}

function gen_id() {
  ID="$(genpass_alnum 8)-$(genpass_alnum 4)-$(genpass_alnum 4)-$(genpass_alnum 4)-$(genpass_alnum 12)"
}

# ----------------------------------------------------------------------------------------------------------------------
# Main Operations
# ----------------------------------------------------------------------------------------------------------------------

sed "s/URL_STUB/$BASE_URL/g" test_body.template > "test.side"

for TEST in $(seq -f '%04.f' 1 "$TOTAL_TESTS"); do
  # ID_STUB
  # TEST_NO_STUB
  gen_id
  sed "s/ID_STUB/$ID/g;s/TEST_NO_STUB/$TEST/g" test.template > "test.out"
  jq '.tests += [input]' test.side test.out > intermediate.out
  echo "\"$ID\"" > suite_id.out
  jq '.suites[].tests += [input]' intermediate.out suite_id.out > test.side

done

rm *.out