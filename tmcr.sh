#!/bin/bash

set -euo pipefail

# GitHub Organization name
ORGANIZATION="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"

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

# Function to assign team to repository
assign_team_to_repo() {
  local team_slug=$1
  local repo_name=$2

  local response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"permission\": \"push\"}" \
    "https://api.github.com/teams/$team_slug/repos/$ORGANIZATION/$repo_name")

  if [[ "$response" -ne 204 ]]; then
    echo "Error assigning team $team_slug to repo $repo_name: HTTP status code $response"
    exit 1
  else
    echo "Team $team_slug assigned to repo $repo_name"
  fi
}

# Function to read JSON file and assign teams to repositories
read_json_and_assign_teams() {
  local json_file=$1

  # Loop through ProjA and its sub_repos
  projA_name=$(jq -r '.ProjA.name' "$json_file")
  sub_repos=$(jq -c '.ProjA.sub_repos[]' "$json_file")
  while IFS= read -r sub_repo; do
    repo_name=$(echo "$sub_repo" | jq -r '.name')
    # Assign teams to repository
    assign_team_to_repo "admin" "$repo_name"
    assign_team_to_repo "dev" "$repo_name"
  done <<< "$sub_repos"
}

# Check if admin team exists
ADMIN_TEAM_ID=$(team_exists "admin")
if [[ "$ADMIN_TEAM_ID" == "false" ]]; then
  echo "Admin team does not exist. Creating..."
  ADMIN_TEAM_ID=$(create_team "admin" "Admin team with full access" "closed")
  echo "Admin team created with ID: $ADMIN_TEAM_ID"
else
  echo "Admin team already exists with ID: $ADMIN_TEAM_ID"
fi

# Check if dev team exists
DEV_TEAM_ID=$(team_exists "dev")
if [[ "$DEV_TEAM_ID" == "false" ]]; then
  echo "Dev team does not exist. Creating..."
  DEV_TEAM_ID=$(create_team "dev" "Development team with write access" "closed")
  echo "Dev team created with ID: $DEV_TEAM_ID"
else
  echo "Dev team already exists with ID: $DEV_TEAM_ID"
fi

# Read JSON file and assign teams to repositories
read_json_and_assign_teams "repos.json"
