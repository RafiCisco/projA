#!/bin/bash

set -euo pipefail

# GitHub Organization name
ORGANIZATION="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Repository name containing the JSON file
repo="projA"

# Branch name
branch="main"

# Path to JSON file in the repository
json_path="repos.json"

# Raw URL of the JSON file
json_url="https://raw.githubusercontent.com/$ORGANIZATION/$repo/$branch/$json_path"

# Fetch the raw content of the JSON file
echo "Fetching JSON content from $json_url..."
json_content=$(curl -s "$json_url")

# Check if the JSON content is empty
if [ -z "$json_content" ]; then
    echo "Error: JSON file is empty or not found."
    exit 1
fi

# Parse JSON content using jq
project=$(echo "$json_content" | jq -r '.project')
repositories=$(echo "$json_content" | jq -r '.repositories[]')

# Output the parsed data
echo "Project: $project"
echo "Repositories:"
while IFS= read -r repo; do
    echo "$repo"
done <<< "$repositories"
