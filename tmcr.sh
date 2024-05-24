#!/bin/bash

# GitHub Personal Access Token (Replace 'YOUR_TOKEN' with your actual token)
token="${GITHUB_TOKEN}"

# GitHub Organization or User name (Replace 'YOUR_ORG' with your actual organization or user name)
#org="RafiCisco"


#!/bin/bash

# GitHub Organization or User name
org="RafiCisco"

# Repository name
repo="projA"

# Branch name
branch="main"

# Path to JSON file in the repository
json_path="repos.json"

# Raw URL of the JSON file
json_url="https://raw.githubusercontent.com/$org/$repo/$branch/$json_path"

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

# Create admin team if not exists
admin_team_response=$(curl -X GET -s -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/$org/teams/admin")
if [[ $(echo "$admin_team_response" | jq -r '.message') == "Not Found" ]]; then
    admin_team_response=$(curl -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/orgs/$org/teams" \
        -d "{\"name\": \"admin\", \"permission\": \"admin\"}")
    echo "Admin team created"
fi

# Create dev team if not exists
dev_team_response=$(curl -X GET -s -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/$org/teams/dev")
if [[ $(echo "$dev_team_response" | jq -r '.message') == "Not Found" ]]; then
    dev_team_response=$(curl -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/orgs/$org/teams" \
        -d "{\"name\": \"dev\", \"permission\": \"push\"}")
    echo "Dev team created"
fi

# Assign teams to repositories
while IFS= read -r repo; do
    repo_name=$(echo "$repo" | tr -d '"')  # Remove double quotes from repository name

    # Add repository to admin team
    curl -X PUT \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/teams/$(echo "$admin_team_response" | jq -r '.id')/repos/$org/$repo_name"
    echo "Assigned admin team to $repo_name"

    # Add repository to dev team
    curl -X PUT \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/teams/$(echo "$dev_team_response" | jq -r '.id')/repos/$org/$repo_name"
    echo "Assigned dev team to $repo_name"
done <<< "$repositories"
