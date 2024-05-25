#!/bin/bash

# Set your GitHub organization name
ORGANIZATION="YourOrganization"

# Set your GitHub token with appropriate permissions
GITHUB_TOKEN="YourGitHubToken"

# Specify the main repository name
MAIN_REPOSITORY="projA"

# Specify the branch name
BRANCH="brpA"

# Specify the sub-repository name
SUB_REPOSITORY="rp1"

# Specify the teams and their corresponding permissions
declare -A TEAMS=(
  ["admin"]="admin"
  ["dev"]="push"
)

# Function to create a team
create_team() {
  local team_name=$1
  local team_description=$2

  # Construct the API request URL
  local url="https://api.github.com/orgs/$ORGANIZATION/teams"

  # Make the API request to create the team
  local response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$team_name\", \"description\": \"$team_description\"}" \
    "$url")

  if [[ "$response" -eq 201 ]]; then
    echo "Successfully created team $team_name."
  else
    echo "Error: Failed to create team $team_name. HTTP status code: $response"
  fi
}

# Function to add a repository to a team with specified permission
add_repo_to_team() {
  local team_slug=$1
  local permission=$2

  # Construct the API request URL
  local url="https://api.github.com/orgs/$ORGANIZATION/teams/$team_slug/repos/$ORGANIZATION/$MAIN_REPOSITORY/$SUB_REPOSITORY"

  # Make the API request to add the repository to the team
  local response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"permission\": \"$permission\"}" \
    "$url")

  if [[ "$response" -eq 204 ]]; then
    echo "Successfully added $SUB_REPOSITORY to team $team_slug with $permission permission."
  else
    echo "Error: Failed to add $SUB_REPOSITORY to team $team_slug. HTTP status code: $response"
  fi
}

# Loop through each team
for team_name in "${!TEAMS[@]}"; do
  # Create the team if it doesn't exist
  create_team "$team_name" "${TEAMS[$team_name]} team"

  # Get the team slug using the team name
  team_slug=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$ORGANIZATION/teams" | \
    jq -r ".[] | select(.name == \"$team_name\") | .slug")

  if [[ -n "$team_slug" ]]; then
    # Add the sub-repository to the team with the specified permission
    add_repo_to_team "$team_slug" "${TEAMS[$team_name]}"
  else
    echo "Error: Team $team_name not found."
  fi
done
