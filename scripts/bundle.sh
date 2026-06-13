#!/bin/bash

# Define the output file
OUTPUT="dist/code_bundle.txt"
mkdir -p dist
echo "Bundling Ansible repository..."

# Clear the output file if it exists
> "$OUTPUT"

echo "# System Configuration Ansible Repository" >> "$OUTPUT"
echo "Generated on: $(date)" >> "$OUTPUT"
echo "---------------------------------------------------" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Find all files, ignoring Git internals, the bundle itself, and the lockfile
find . -type f -not -path "*/\.git/*" -not -name "bundle.sh" -not -path "*/dist/*" -not -name "*.lock" | sort | while read -r file; do
    echo "### FILE: $file" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    cat "$file" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    echo "" >> "$OUTPUT"
done

echo "Bundle complete. Contents written to $OUTPUT."
