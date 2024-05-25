#!/bin/bash

set -euo pipefail

# GitHub Organization name
ORGANIZATION="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Variables
TEAM_NAMES=("admin" "dev")
TEAM_DESCRIPTIONS=("Admin team with full access" "Development team with write access")
TEAM_PRIVACY="closed"  # or "secret"
MAIN_REPOSITORY="projA"  # Main repository name
SUB_DIRECTORIES=("rp1" "rp2")  # Subdirectories within the main repository

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

# Function to add repository to a team with specified permission
add_repo_to_team() {
  local team_slug=$1
  local repo_name=$2
  local permission=$3

  local response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"permission\": \"$permission\"}" \
    "https://api.github.com/orgs/$ORGANIZATION/teams/$team_slug/repos/$ORGANIZATION/$repo_name")

  if [[ "$response" -ne 204 ]]; then
    echo "Error adding repo $repo_name to team $team_slug: HTTP status code $response"
    exit 1
  else
    echo "Repo $repo_name added to team $team_slug with $permission permission"
  fi
}

# Function to check if a repository exists
repo_exists() {
  local repo_name=$1

  local response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$ORGANIZATION/$repo_name")

  if [[ "$response" -eq 200 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Loop through team names and create teams if they don't exist
for team_name in "${TEAM_NAMES[@]}"; do
  if [[ $(team_exists "$team_name") == "false" ]]; then
    create_team "$team_name" "${TEAM_DESCRIPTIONS[$i]}" "$TEAM_PRIVACY"
  fi
done

# Loop through subdirectories and add them to the appropriate teams
for sub_directory in "${SUB_DIRECTORIES[@]}"; do
  for team_name in "${TEAM_NAMES[@]}"; do
    if [[ $(repo_exists "$MAIN_REPOSITORY/$sub_directory") == "true" ]]; then
      team_id=$(team_exists "$team_name")
      add_repo_to_team "$team_id" "$MAIN_REPOSITORY/$sub_directory" "admin"
    else
      echo "Repository $MAIN_REPOSITORY/$sub_directory does not exist."
    fi
  done
done
