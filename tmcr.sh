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

# Check if JSON file exists
if [ ! -f "$json_file" ]; then
    echo "Error: JSON file '$json_file' not found."
    exit 1
fi

# Read JSON file
project=$(jq -r '.project' "$json_file")
repositories=$(jq -c '.repositories[]' "$json_file")

# Create project if not exists
project_id=$(curl -X GET -s -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/$org/projects" | jq -r --arg project "$project" '.[] | select(.name == $project) | .id')
if [ -z "$project_id" ]; then
    project_response=$(curl -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/orgs/$org/projects" \
        -d "{\"name\": \"$project\", \"body\": \"\", \"auto_init\": false}")
    project_id=$(echo "$project_response" | jq -r '.id')
    echo "Project '$project' created with ID: $project_id"
fi

# Add repositories to project
while IFS= read -r repo; do
    repo_name=$(echo "$repo" | tr -d '"')  # Remove double quotes from repository name

    # Add repository to project
    curl -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/projects/$project_id/columns" \
        -d "{\"name\": \"$repo_name\", \"position\": \"last\"}"
    echo "Added $repo_name to project '$project'"
done <<< "$repositories"
