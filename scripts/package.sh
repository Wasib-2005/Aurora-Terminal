#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version=$(sed -n 's/^Version=//p' "$project_dir/metadata.desktop")

if [ -z "$version" ]; then
    printf '%s\n' "Could not read Version from metadata.desktop" >&2
    exit 1
fi

output_dir=${1:-"$project_dir/dist"}
mkdir -p "$output_dir"
output_dir=$(CDPATH= cd -- "$output_dir" && pwd)
archive="$output_dir/Aurora-Terminal-$version.tar.gz"

tar -czf "$archive" \
    -C "$project_dir" \
    --transform='s|^|Aurora-Terminal/|' \
    Main.qml metadata.desktop LICENSE \
    assets/aurora-terminal-icon.svg assets/aurora-terminal-preview.png

printf 'Created %s\n' "$archive"
