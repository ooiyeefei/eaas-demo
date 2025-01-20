#!/bin/bash

# Validate arguments
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <BASE_URL> <API_KEY> <PROJECT_NAME> <CLUSTER_NAME> <COMMAND>"
  exit 1
fi

BASE_URL="$1"
API_KEY="$2"
PROJECT_NAME="$3"
CLUSTER_NAME="$4"
COMMAND="$5"

# Fetch Project ID
PROJECT_ID=$(curl -s -X GET "https://${BASE_URL}/auth/v1/projects/?limit=48&offset=0&order=ASC&orderby=name&q=" \
  -H 'User-Agent: Mozilla/5.0' \
  -H "Referer: https://${BASE_URL}/" \
  -H "X-RAFAY-API-KEYID: ${API_KEY}" \
  | jq -r --arg name "${PROJECT_NAME}" '.results[] | select(.name == $name) | .id')

if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID not found for project name $PROJECT_NAME"
  exit 1
fi

# Fetch Cluster ID
CLUSTER_ID=$(curl -s -X GET "https://${BASE_URL}/edge/v1/projects/$PROJECT_ID/edges/?limit=25&offset=0&q=" \
  -H 'accept: application/json, text/plain, */*' \
  -H "X-RAFAY-API-KEYID: ${API_KEY}" \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: https://${BASE_URL}/" \
  | jq -r --arg name "${CLUSTER_NAME}" '.results[] | select(.name == $name) | .id')

if [ -z "$CLUSTER_ID" ]; then
  echo "Error: Cluster ID not found for cluster name $CLUSTER_NAME"
  exit 1
fi

# Execute Command
POST_RESPONSE=$(curl -s -X POST \
  "https://${BASE_URL}/cmdexec/v1/projects/$PROJECT_ID/edges/$CLUSTER_ID/execute/" \
  -H "accept: application/json" \
  -H "X-RAFAY-API-KEYID: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"target_type\": \"cluster\", \"command\": \"$COMMAND\", \"timeout\": 120}")

EXEC_ID=$(echo "$POST_RESPONSE" | jq -r '.Id')

if [ -z "$EXEC_ID" ] || [ "$EXEC_ID" == "null" ]; then
  echo "Error: Failed to retrieve execution ID. Response: $POST_RESPONSE"
  exit 1
fi

# Fetch Execution Result
GET_RESPONSE=$(curl -s -X GET \
  "https://${BASE_URL}/cmdexec/v1/projects/$PROJECT_ID/edges/$CLUSTER_ID/execution/$EXEC_ID/" \
  -H "accept: application/json" \
  -H "X-RAFAY-API-KEYID: ${API_KEY}")

RETURN_FIELD=$(echo "$GET_RESPONSE" | jq -r '.NodeResponses[0].Resp.Return')

if [ -z "$RETURN_FIELD" ] || [ "$RETURN_FIELD" == "null" ]; then
  echo "Error: Failed to retrieve the Return field. Response: $GET_RESPONSE"
  exit 1
fi

echo -e "Command Output:\n$RETURN_FIELD"
