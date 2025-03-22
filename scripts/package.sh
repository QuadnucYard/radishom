#!/bin/bash

# Check if target directory argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <target-directory>"
  exit 1
fi

TARGET_DIR="$1"


# If the target directory exists, remove its contents; otherwise, create it.
if [ -d "$TARGET_DIR" ]; then
  rm -rf "$TARGET_DIR"/*
else
  mkdir -p "$TARGET_DIR"
fi

# Create a temporary directory for packaging
TEMP_DIR=$(mktemp -d) || { echo "Failed to create temp directory"; exit 1; }

# Copy files and directories into the temp directory
cp --parents examples/*.svg "$TEMP_DIR" 2>/dev/null
cp --parents -r src "$TEMP_DIR" 2>/dev/null
cp --parents LICENSE "$TEMP_DIR" 2>/dev/null
cp --parents README.md "$TEMP_DIR" 2>/dev/null
cp --parents typst.toml "$TEMP_DIR" 2>/dev/null

# Create a 7z archive of the temporary directory.
# Archive name will be based on the temporary directory name.
ARCHIVE_NAME="$TARGET_DIR/radishom.7z"

7z a "$ARCHIVE_NAME" "$TEMP_DIR"/*

# Remove the temporary directory
rm -rf "$TEMP_DIR"

# Copy docs/manual.pdf directly to the target directory
cp docs/manual.pdf "$TARGET_DIR" 2>/dev/null

echo "Packaging complete. Archive saved at $ARCHIVE_NAME"
