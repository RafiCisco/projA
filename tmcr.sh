#!/bin/bash

# Read the JSON file and extract repository information
json_file="repos.json"
project_name=$(jq -r '.ProjA.name' "$json_file")
sub_repos=$(jq -c '.ProjA.sub_repos[]' "$json_file")

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
