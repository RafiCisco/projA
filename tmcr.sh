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



# Function to create a team
create_team() {
  local team_name=$1
  local team_description=$2
  local team_privacy=$3

  local response=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$team_name\", \"description\": \"$team_description\", \"privacy\": \"$team_privacy\"}" \
    "https://api.github.com/orgs/$ORGANIZATION/teams")

  local team_id=$(echo "$response" | jq -r '.id')
  local error_message=$(echo "$response" | jq -r '.message')

  if [[ "$team_id" == "null" ]]; then
    echo "Error creating team $team_name: $error_message"
    exit 1
  else
    echo "$team_id"
  fi
}

# Function to assign a team to a repository
assign_team_to_repo() {
  local team_slug=$1
  local repo_name=$2
  local permission=$3

  local response=$(curl -s -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{\"permission\": \"$permission\"}" \
    "https://api.github.com/teams/$team_slug/repos/$ORGANIZATION/$repo_name")

  if [[ $(echo "$response" | jq -r '.message') != "null" ]]; then
    echo "Error assigning team $team_slug to repository $repo_name: $(echo "$response" | jq -r '.message')"
  else
    echo "Assigned team $team_slug to repository $repo_name with $permission permission"
  fi
}

# Function to create and assign teams to repositories
create_and_assign_teams() {
  local json_content=$1

  # Parse JSON content using jq
  local project=$(echo "$json_content" | jq -r '.project')
  local repositories=$(echo "$json_content" | jq -r '.repositories[]')

  # Output the parsed data
  echo "Project: $project"
  echo "Repositories:"
  while IFS= read -r repo_name; do
    echo "$repo_name"
    
    # Create admin team if it doesn't exist
    admin_team_id=$(create_team "admin" "Admin team with full access" "closed")
    echo "Admin Team ID: $admin_team_id"

    # Create dev team if it doesn't exist
    dev_team_id=$(create_team "dev" "Development team with write access" "closed")
    echo "Dev Team ID: $dev_team_id"

    # Assign admin team to repository
    assign_team_to_repo "$admin_team_id" "$repo_name" "admin"

    # Assign dev team to repository
    assign_team_to_repo "$dev_team_id" "$repo_name" "push"

  done <<< "$repositories"
}

# Fetch the raw content of the JSON file
echo "Fetching JSON content from $json_url..."
json_content=$(curl -s "$json_url")

# Check if the JSON content is empty
if [ -z "$json_content" ]; then
    echo "Error: JSON file is empty or not found."
    exit 1
fi

# Create and assign teams to repositories
create_and_assign_teams "$json_content"
