#!/bin/bash

# Define your GitHub organization name
ORG_NAME="RafiCisco"

# Define your GitHub access token
ACCESS_TOKEN="${GITHUB_TOKEN}"

# Define your projects and repositories
PROJECTS=("projA")
REPOS=("rp1" "rp2" "rp3" "rp4" "rp5")

# Loop through projects
for PROJECT in "${PROJECTS[@]}"; do
    # Create admin team for project
    ADMIN_TEAM_ID=$(curl -s -X POST \
        -H "Authorization: token $ACCESS_TOKEN" \
        -d '{"name": "admin", "description": "Admin team for '"$PROJECT"'"}' \
        "https://api.github.com/orgs/$ORG_NAME/teams" | jq -r '.id')

    # Create dev team for project
    DEV_TEAM_ID=$(curl -s -X POST \
        -H "Authorization: token $ACCESS_TOKEN" \
        -d '{"name": "dev", "description": "Dev team for '"$PROJECT"'"}' \
        "https://api.github.com/orgs/$ORG_NAME/teams" | jq -r '.id')

    # Loop through repositories
    for REPO in "${REPOS[@]}"; do
        # Assign repository to admin team
        curl -s -X PUT \
            -H "Authorization: token $ACCESS_TOKEN" \
            "https://api.github.com/teams/$ADMIN_TEAM_ID/repos/$ORG_NAME/$REPO"

        # Assign repository to dev team
        curl -s -X PUT \
            -H "Authorization: token $ACCESS_TOKEN" \
            "https://api.github.com/teams/$DEV_TEAM_ID/repos/$ORG_NAME/$REPO"
    done
done

echo "Teams and repositories created and assigned successfully."
