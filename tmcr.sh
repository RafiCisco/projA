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



# Function to create a team if it doesn't exist
create_team_if_not_exists() {
    local team_name=$1
    local team_description=$2

    # Check if the team already exists
    local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/orgs/$ORGANIZATION/teams")
    local team_id=$(echo "$response" | jq -r ".[] | select(.name == \"$team_name\") | .id")

    if [[ -z "$team_id" ]]; then
        # Team does not exist, create it
        echo "Creating team '$team_name'..."
        response=$(curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            -d "{\"name\": \"$team_name\", \"description\": \"$team_description\"}" \
            "https://api.github.com/orgs/$ORGANIZATION/teams")
        team_id=$(echo "$response" | jq -r '.id')
    else
        echo "Team '$team_name' already exists with ID $team_id."
    fi

    echo "$team_id"
}

# Function to assign a team to a repository with the specified permission
assign_team_to_repo() {
    local team_id=$1
    local repo_name=$2
    local permission=$3

    echo "Assigning team with ID '$team_id' to repository '$repo_name' with '$permission' permission..."
    local response=$(curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"permission\": \"$permission\"}" \
        "https://api.github.com/teams/$team_id/repos/$ORGANIZATION/$repo_name")

    if [[ $(echo "$response" | jq -r '.message') != "null" ]]; then
        echo "Error assigning team to repository: $(echo "$response" | jq -r '.message')"
    else
        echo "Assigned team to repository successfully."
    fi
}

# Create admin and dev teams (if they don't exist)
admin_team_id=$(create_team_if_not_exists "admin" "Admin team with full access")
dev_team_id=$(create_team_if_not_exists "dev" "Development team with write access")

# Assign admin and dev teams to each repository
while IFS= read -r repo_name; do
    assign_team_to_repo "$admin_team_id" "$repo_name" "admin"
    assign_team_to_repo "$dev_team_id" "$repo_name" "push"
done <<< "$repositories"
