#!/bin/bash
set -euo pipefail
# GitHub personal access token with appropriate permissions
TOKEN="${GITHUB_TOKEN}"

# Organization name
ORG_NAME="RafiCisco"

# Function to create a team
create_team() {
    team_name=$1
    team_desc=$2
    team_permission=$3

    # Create the team
    response=$(curl -X POST \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/orgs/$ORG_NAME/teams" \
        -d "{\"name\":\"$team_name\",\"description\":\"$team_desc\",\"permission\":\"$team_permission\"}" \
        -s)

    # Parse the response and extract team details
    team_name=$(echo "$response" | jq -r '.name')
    team_id=$(echo "$response" | jq -r '.id')
    team_desc=$(echo "$response" | jq -r '.description')

    # Output team details
    echo "Team Name: $team_name"
    echo "Team ID: $team_id"
    echo "Description: $team_desc"
    echo
}

# Main script
echo "Creating Admin Team..."
create_team "AdminTeam" "Administrative Team" "admin"

echo "Creating Dev Team..."
create_team "DevTeam" "Development Team" "push"
