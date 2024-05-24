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

# Variables
TEAM_NAMES=("admin" "dev")
TEAM_DESCRIPTIONS=("Admin team with full access" "Development team with write access")
TEAM_PERMISSIONS=("admin" "push")
TEAM_PRIVACY="closed"  # or "secret"

# Function to check if a team exists
team_exists() {
  local team_name=$1

  local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$ORGANIZATION/teams")

  local team_id=$(echo "$response" | jq -r ".[] | select(.name == \"$team_name\") | .id")

  if [[ -n "$team_id" ]]; then
    echo "$team_id"
  else
    echo "false"
  fi
}

# Function to assign a team to a repository
assign_team_to_repo() {
  local team_slug=$1
  local repo_name=$2
  local permission=$3

  local api_url="https://api.github.com/repos/$ORGANIZATION/projA/teams/$team_slug/repos/$ORGANIZATION/projA/$repo_name"

  echo "API URL: $api_url"
  
  local response=$(curl -s -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$api_url" \
    -d "{\"permission\": \"$permission\"}")

  if [[ $(echo "$response" | jq -r '.message') != "null" ]]; then
    echo "Error assigning team $team_slug to repository $repo_name: $(echo "$response" | jq -r '.message')"
  else
    echo "Assigned team $team_slug to repository $repo_name with $permission permission"
  fi
}

# Function to get team slug from team ID
get_team_slug() {
  local team_id=$1

  local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$ORGANIZATION/teams")

  local team_slug=$(echo "$response" | jq -r ".[] | select(.id==$team_id) | .slug")

  if [[ -z "$team_slug" ]]; then
    echo "Error: Team slug not found for team ID $team_id"
    exit 1
  else
    echo "$team_slug"
  fi
}

# Function to get team details
get_team_details() {
  local team_slug=$1

  local response=$(curl -s -X GET \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.github.com/orgs/$ORGANIZATION/teams/$team_slug")

  echo "$response" | jq '.'
}

# Function to assign a team to a repository
assign_team_to_repo() {
  local team_slug=$1
  local repo_name=$2
  local permission=$3

  local api_url="https://api.github.com/repos/$ORGANIZATION/projA/teams/$team_slug/repos/$ORGANIZATION/projA-$repo_name"

  echo "API URL: $api_url"
  
  local response=$(curl -s -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$api_url" \
    -d "{\"permission\": \"$permission\"}")

  if [[ $(echo "$response" | jq -r '.message') != "null" ]]; then
    echo "Error assigning team $team_slug to repository $repo_name: $(echo "$response" | jq -r '.message')"
  else
    echo "Assigned team $team_slug to repository $repo_name with $permission permission"
  fi
}

# Loop through team names and descriptions
for i in "${!TEAM_NAMES[@]}"; do
  TEAM_NAME="${TEAM_NAMES[$i]}"
  TEAM_DESCRIPTION="${TEAM_DESCRIPTIONS[$i]}"
  TEAM_PERMISSION="${TEAM_PERMISSIONS[$i]}"

  # Check if the team already exists
  TEAM_ID=$(team_exists "$TEAM_NAME")
  if [[ "$TEAM_ID" != "false" ]]; then
    echo "Team '$TEAM_NAME' already exists with ID $TEAM_ID."
    TEAM_SLUG=$(get_team_slug "$TEAM_ID")
  else
    # Create the team and get its details
    TEAM_ID=$(create_team "$TEAM_NAME" "$TEAM_DESCRIPTION" "$TEAM_PRIVACY")
    echo "Team '$TEAM_NAME' created with ID $TEAM_ID"

    # Fetch the team slug using the team ID
    TEAM_SLUG=$(get_team_slug "$TEAM_ID")
  fi

  echo "Fetching details for team '$TEAM_NAME' with slug '$TEAM_SLUG'..."
  get_team_details "$TEAM_SLUG"

  # Assign team to each repository
  while IFS= read -r repo; do
    echo "Assigning team '$TEAM_SLUG' to repository '$project/$repo' with '$TEAM_PERMISSION' permission..."
    assign_team_to_repo "$TEAM_SLUG" "$repo" "$TEAM_PERMISSION"
  done <<< "$repositories"
done
