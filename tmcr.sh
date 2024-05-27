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



