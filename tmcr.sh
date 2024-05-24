#!/bin/bash

# GitHub Personal Access Token (Replace 'YOUR_TOKEN' with your actual token)
token="${GITHUB_TOKEN}"

# GitHub Organization or User name (Replace 'RafiCisco' with your actual organization or user name)
org="RafiCisco"

# Function to create a team if it doesn't exist
create_team() {
    local team_name="$1"
    local team_permission="$2"

    # Check if the team already exists
    team_response=$(curl -X GET -s -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/$org/teams/$team_name")
    if [[ $(echo "$team_response" | jq -r '.message') == "Not Found" ]]; then
        # Team doesn't exist, so create it
        team_response=$(curl -X POST \
            -H "Authorization: token $token" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/orgs/$org/teams" \
            -d "{\"name\": \"$team_name\", \"permission\": \"$team_permission\"}")
        echo "Team '$team_name' created"
    fi
}

# Function to assign team to a repository
assign_team_to_repo() {
    local team_name="$1"
    local repo_name="$2"

    # Get team ID
    team_id=$(curl -s -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/$org/teams/$team_name" | jq -r '.id')

    # Assign team to repository
    curl -X PUT \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/teams/$team_id/repos/$org/$repo_name"
    echo "Assigned $team_name team to $repo_name"
}

# Path to JSON file containing repository information
json_path="repos.json"

# Raw URL of the JSON file
json_url="https://raw.githubusercontent.com/$org/projA/main/$json_path"

# Fetch the raw content of the JSON file
json_content=$(curl -s "$json_url")

# Parse JSON content using jq
project=$(echo "$json_content" | jq -r '.project')
repositories=$(echo "$json_content" | jq -c '.repositories[]')

# Create admin team if not exists
create_team "admin" "admin"

# Create dev team if not exists
create_team "dev" "push"

# Assign teams to repositories
for repo in $(echo "$repositories" | jq -r '.[]'); do
    repo_name=$(echo "$repo" | jq -r '.name')
    sub_repositories=$(echo "$repo" | jq -c '.subrepositories[]')
    
    # Assign admin team to main repository
    assign_team_to_repo "admin" "$repo_name"

    # Assign dev team to main repository
    assign_team_to_repo "dev" "$repo_name"

    # Assign teams to subrepositories
    for sub_repo in $(echo "$sub_repositories" | jq -r '.[]'); do
        assign_team_to_repo "admin" "$sub_repo"
        assign_team_to_repo "dev" "$sub_repo"
    done
done
