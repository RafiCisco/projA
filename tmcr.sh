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
while IFS= read -r repo_name; do
    echo "$repo_name"
    
    # Loop through team names and descriptions
    for i in "${!TEAM_NAMES[@]}"; do
        TEAM_NAME="${TEAM_NAMES[$i]}"
        TEAM_DESCRIPTION="${TEAM_DESCRIPTIONS[$i]}"
        TEAM_PERMISSION="${TEAM_PERMISSIONS[$i]}"

        # Check if the team already exists
        response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/orgs/$ORGANIZATION/teams")
        team_id=$(echo "$response" | jq -r ".[] | select(.name == \"$TEAM_NAME\") | .id")

        if [[ -z "$team_id" ]]; then
            # Team does not exist, create it
            echo "Creating team '$TEAM_NAME'..."
            response=$(curl -s -X POST \
                -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3+json" \
                -d "{\"name\": \"$TEAM_NAME\", \"description\": \"$TEAM_DESCRIPTION\"}" \
                "https://api.github.com/orgs/$ORGANIZATION/teams")
            team_id=$(echo "$response" | jq -r '.id')
        else
            echo "Team '$TEAM_NAME' already exists with ID $team_id."
        fi

        # Assign team to repository
        echo "Assigning team '$TEAM_NAME' to repository '$repo_name' with '$TEAM_PERMISSION' permission..."
        response=$(curl -s -X PUT \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            -d "{\"permission\": \"$TEAM_PERMISSION\"}" \
            "https://api.github.com/teams/$team_id/repos/$ORGANIZATION/$repo_name")
    done
done <<< "$repositories"
