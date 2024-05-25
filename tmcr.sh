#!/bin/bash

set -euo pipefail

# GitHub Organization name
ORGANIZATION="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"


# Specify the main repository name
MAIN_REPOSITORY="projA"

# Specify the sub-repositories (you can add more if needed)
SUB_REPOSITORIES=("rp1" "rp2" )

# Specify the teams and their corresponding permissions
declare -A TEAMS=(
  ["admin"]="admin"
  ["dev"]="push"
)

# Function to add a repository to a team with specified permission
add_repo_to_team() {
  local team_slug=$1
  local repo_name=$2
  local permission=$3

  # Construct the API request URL
  local url="https://api.github.com/orgs/$ORGANIZATION/teams/$team_slug/repos/$ORGANIZATION/$MAIN_REPOSITORY/$repo_name"

  # Make the API request to add the repository to the team
  local response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"permission\": \"$permission\"}" \
    "$url")

  if [[ "$response" -eq 204 ]]; then
    echo "Successfully added $repo_name to team $team_slug with $permission permission."
  else
    echo "Error: Failed to add $repo_name to team $team_slug. HTTP status code: $response"
  fi
}

# Loop through each sub-repository
for repo_name in "${SUB_REPOSITORIES[@]}"; do
  # Loop through each team
  for team_name in "${!TEAMS[@]}"; do
    # Get the team slug using the team name
    team_slug=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/orgs/$ORGANIZATION/teams" | \
      jq -r ".[] | select(.name == \"$team_name\") | .slug")

    if [[ -n "$team_slug" ]]; then
      # Add the repository to the team with the specified permission
      add_repo_to_team "$team_slug" "$repo_name" "${TEAMS[$team_name]}"
    else
      echo "Error: Team $team_name not found."
    fi
  done
done
