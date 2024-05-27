#!/bin/bash

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

# Main script starts here

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
  local permission=$3

  local response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"permission\": \"$permission\"}" \
    "https://api.github.com/orgs/$ORGANIZATION/teams/$team_slug/repos/$ORGANIZATION/$repo_name")

  if [[ "$response" -eq 204 ]]; then
    echo "Assigned team $team_slug to repo $repo_name with $permission permission"
  else
    echo "Error assigning team $team_slug to repo $repo_name: HTTP status code $response"
    exit 1
  fi
}

# Read JSON file and assign teams to main repository
read_json_and_assign_teams() {
  local json_file=$1

  # Extract project name and sub-repositories
  project_name=$(jq -r '.projA.name' "$json_file")
  sub_repos=$(jq -c '.projA.sub_repos[]' "$json_file")

  echo "Project: $project_name"

  # Assign teams to main repository
  main_repo="projA"
  echo "Assigning teams to main repository: $main_repo"
  for team_name in "admin" "dev"; do
    team_id=$(team_exists "$team_name")
    if [[ "$team_id" == "false" ]]; then
      echo "$team_name team does not exist. Creating..."
      team_id=$(create_team "$team_name" "$team_name team with appropriate access" "closed")
      echo "$team_name team created with ID: $team_id"
    else
      echo "$team_name team already exists with ID: $team_id"
    fi

    assign_team_to_repo "$team_id" "$main_repo" "push"
  done
}

# Read JSON file and assign teams to main repository
read_json_and_assign_teams "repos.json"
