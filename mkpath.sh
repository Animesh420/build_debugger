#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 -d PATH    Create nested directories (mkdir -p PATH)
  $0 -f PATH    Create parent directories and touch PATH (treat last element as file)
Examples:
  $0 -d A/B/C
  $0 -f A/B/file.txt
EOF
  exit 2
}

if [[ $# -ne 2 ]]; then usage; fi

opt=$1
path=$2

case "$opt" in
  -d)
    mkdir -p -- "$path"
    ;;
  -f)
    # reject trailing slash for file case
    if [[ "${path: -1}" == "/" ]]; then
      echo "Error: file path must not end with '/'" >&2
      exit 1
    fi
    dir=$(dirname -- "$path")
    if [[ "$dir" == "." ]]; then
      touch -- "$path"
    else
      mkdir -p -- "$dir"
      touch -- "$path"
    fi
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "Unknown option: $opt" >&2
    usage
    ;;
esac