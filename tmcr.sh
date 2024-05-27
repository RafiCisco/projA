#!/bin/bash

# Path to the JSON file
json_file="repos.json"

# Function to read and display the project and its sub-repositories
read_and_display_repos() {
  local json_file=$1

  # Extract project name and sub-repositories
  project_name=$(jq -r '.ProjA.name' "$json_file")
  sub_repos=$(jq -c '.ProjA.sub_repos[]' "$json_file")

  echo "Project: $project_name"

  while IFS= read -r sub_repo; do
    repo_name=$(echo "$sub_repo" | jq -r '.name')
    repo_description=$(echo "$sub_repo" | jq -r '.description')
    repo_url=$(echo "$sub_repo" | jq -r '.url')

    echo "Repository: $repo_name"
    echo "Description: $repo_description"
    echo "URL: $repo_url"
    echo ""
  done <<< "$sub_repos"
}

# Read and display the repositories from the JSON file
read_and_display_repos "$json_file"
