#!/bin/bash

set -euo pipefail

# GitHub Organization name
ORGANIZATION="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"


# Create Admin and Dev Teams
create_team() {
    local team_name=$1
    local team_description=$2

    local response=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"name\": \"$team_name\", \"description\": \"$team_description\", \"privacy\": \"closed\"}" \
        "https://api.github.com/orgs/$ORGANIZATION/teams")

    local team_id=$(echo "$response" | jq -r '.id')
    if [ "$team_id" != "null" ]; then
        echo "Team '$team_name' created with ID $team_id"
    else
        echo "Error creating team '$team_name': $(echo "$response" | jq -r '.message')"
        exit 1
    fi
}

# Assign Team to Repository
assign_team_to_repo() {
    local team_id=$1
    local repo_name=$2
    local permission=$3

    local response=$(curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"permission\": \"$permission\"}" \
        "https://api.github.com/repos/$ORGANIZATION/$repo_name/teams/$team_id")

    if [[ $(echo "$response" | jq -r '.message') != "null" ]]; then
        echo "Error assigning team to repository: $(echo "$response" | jq -r '.message')"
        exit 1
    else
        echo "Assigned team to repository successfully."
    fi
}

# Create Admin Team
create_team "admin" "Admin team with full access"

# Create Dev Team
create_team "dev" "Development team with write access"

# Assign Admin Team to Repositories
admin_team_id=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$ORGANIZATION/teams/admin" | jq -r '.id')
repositories=("rp1")  # List of repositories to assign

for repo_name in "${repositories[@]}"; do
    assign_team_to_repo "$admin_team_id" "$repo_name" "admin"
done

# Assign Dev Team to Repositories
dev_team_id=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$ORGANIZATION/teams/dev" | jq -r '.id')

for repo_name in "${repositories[@]}"; do
    assign_team_to_repo "$dev_team_id" "$repo_name" "push"
done

echo "Script completed successfully."
