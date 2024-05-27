#!/bin/bash
set -euo pipefail
# Read the JSON file and extract repository information
json_file="repos.json"
project_name=$(jq -r '.projA.name' "$json_file")
sub_repos=$(jq -c '.projA.sub_repos[]' "$json_file")

echo "Project: $project_name"

# Loop through sub-repositories and display their details
while IFS= read -r sub_repo; do
    name=$(echo "$sub_repo" | jq -r '.name')
    description=$(echo "$sub_repo" | jq -r '.description')
    url=$(echo "$sub_repo" | jq -r '.url')

    echo "Sub-repository: $name"
    echo "Description: $description"
    echo "URL: $url"
    echo
done <<< "$sub_repos"

# Main script starts here projA to check exist or not
# GitHub Organization name
ORGANIZATION="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Function to check if a repository exists
repository_exists() {
  local repo_name=$1

  local response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$ORGANIZATION/$repo_name")

  if [[ "$response" -eq 200 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Function to assign teams to the repository
assign_teams_to_repo() {
  local repo_name=$1

  # Your code to assign teams to the repository goes here
  # Use the GitHub API to assign teams to the repository
}

# Check if the repository projA exists
if [[ "$(repository_exists "projA")" == "true" ]]; then
  echo "Repository projA exists."
  
  # Call the function to assign teams to the repository
  assign_teams_to_repo "projA"
else
  echo "Repository projA does not exist."
fi

# check projects and repos
# GitHub Organization name
ORGANIZATION="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Function to fetch all repositories in the organization
fetch_repositories() {
  local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$ORGANIZATION/repos?per_page=100")

  echo "$response"
}

# Call the function to fetch repositories
repositories=$(fetch_repositories)

# Extract repository names from the response and display them
echo "Repositories in $ORGANIZATION organization:"
echo "$repositories" | jq -r '.[].full_name'

#assigning each repo to the team
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
    -d "{\"permission\": \"admin\"}" \
    "https://api.github.com/orgs/$ORGANIZATION/teams/$team_slug/repos/$ORGANIZATION/$repo_name")

  if [[ "$response" -ne 204 ]]; then
    echo "Error assigning team $team_slug to repo $repo_name: HTTP status code $response"
    exit 1
  else
    echo "Team $team_slug assigned to repo $repo_name"
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

# Assign teams to main repository projA
for repo in $(jq -r '.projA.sub_repos[] | .name' repos.json); do
  assign_team_to_repo "$ADMIN_TEAM_ID" "$repo"
  assign_team_to_repo "$DEV_TEAM_ID" "$repo"
done

