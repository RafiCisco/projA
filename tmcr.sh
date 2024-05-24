#!/bin/bash
# Variables
#ORG_NAME="RafiCisco"  # Replace with your actual organization name
#GITHUB_TOKEN="${GITHUB_TOKEN}"  # Replace with your GitHub personal access token


# GitHub Personal Access Token (Replace 'YOUR_TOKEN' with your actual token)
token="${GITHUB_TOKEN}"

# GitHub Organization or User name (Replace 'YOUR_ORG' with your actual organization or user name)
org="RafiCisco"

# Path to JSON file containing repository information
# Raw URL of the JSON file
#json_url="https://raw.githubusercontent.com/$org/$repo/$branch/$json_path"

#json_file="https://github.com/RafiCisco/projA/blob/main/repos.json"
json_file=repos.json

# Fetch the raw content of the JSON file
json_content=$(curl -s "$json_url")

# Check if the JSON content is empty
if [ -z "$json_content" ]; then
    echo "Error: JSON file is empty or not found."
    exit 1
fi

# Parse JSON content using jq
project=$(echo "$json_content" | jq -r '.project')
repositories=$(echo "$json_content" | jq -c '.repositories[]')

# Output the parsed data
echo "Project: $project"
echo "Repositories:"
while IFS= read -r repo; do
    echo "$repo"
done <<< "$repositories"
