#!/bin/bash

set -euo pipefail

# GitHub Organization name
ORG="RafiCisco"

# GitHub Token with appropriate permissions
GITHUB_TOKEN="${GITHUB_TOKEN}"

#!/bin/bash

# Replace these variables with your own values
REPO="rp1"  # Replace with the repo you want to assign these teams to
ADMIN_TEAM="admin_team"
DEV_TEAM="dev_team"

# Function to create a team
create_team() {
    local TEAM_NAME=$1
    local PERMISSION=$2

    # Create the team
    curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/orgs/$ORG/teams \
    -d "{\"name\":\"$TEAM_NAME\", \"permission\":\"$PERMISSION\"}"
}

# Function to add a team to a repository with a specific permission
add_team_to_repo() {
    local TEAM_NAME=$1
    local PERMISSION=$2

    # Get the team ID
    TEAM_ID=$(curl -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/orgs/$ORG/teams/$TEAM_NAME | jq -r .id)

    # Add the team to the repository with the specified permission
    curl -X PUT -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/teams/$TEAM_ID/repos/$ORG/$REPO \
    -d "{\"permission\":\"$PERMISSION\"}"
}

# Create admin team
create_team $ADMIN_TEAM "admin"

# Create dev team
create_team $DEV_TEAM "push"

# Allow some time for the teams to be created
sleep 5

# Add admin team to repository with admin permission
add_team_to_repo $ADMIN_TEAM "admin"

# Add dev team to repository with write permission
add_team_to_repo $DEV_TEAM "push"
