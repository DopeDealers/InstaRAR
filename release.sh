#!/bin/bash

# release.sh, Version 0.2.0
# Copyright (c) 2025, Cyci
# https://github.com/Cyci/InstaRAR
# Bundler for InstaRAR (fork of oneclickwinrar)

set -euo pipefail
IFS=$'\n\t'

# [ INFO ]
version=$(<VERSION)
name="instarar"

# [ FILES LIST ]
files_list=(
  "ir_hardened.cmd"
  "ir_license.cmd"
  "ir_unlicense.cmd"
  "ir_hardened.ps1"
  "ir_license.ps1"
  "ir_unlicense.ps1"
)

complete_release="$name-$version.zip"

# Create necessary directories
mkdir -p dist release

# Clean previous dist
rm -rf dist/*

# Copy core files
cp ./LICENSE ./VERSION ./README.md dist

# Copy scripts
for file in "${files_list[@]}"; do
  cp "$file" dist
done

# Copy bin folder if exists
if [[ -d "bin" ]]; then
  cp -r bin dist
fi

# Move into dist to create zip
cd dist

# Create zip archive
if ! command -v zip &>/dev/null; then
  echo "ERROR: zip command not found. Please install zip and retry."
  exit 1
fi

zip -q -r "$complete_release" * || { echo "ERROR: Failed to create archive."; exit 1; }

cd ..

# Move archive to release folder
mv "dist/$complete_release" "release/$complete_release"

# Confirm success
if [[ -f "release/$complete_release" ]]; then
  echo "✅ Release archive created successfully: release/$complete_release"
else
  echo "❌ Release failed!"
  exit 1
fi

# Clean up
rm -rf dist
