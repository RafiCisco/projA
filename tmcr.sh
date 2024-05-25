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
