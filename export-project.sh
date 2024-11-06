#!/bin/bash

# 載入 .env 檔案
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# 驗證是否已載入變數
if [ -z "$GITLAB_TOKEN_SOURCE" ] || [ -z "$GITLAB_TOKEN_DEST" ] || [ -z "$GITLAB_SERVER_DOMAIN" ]; then
  echo "Error: GITLAB_TOKEN_SOURCE, GITLAB_TOKEN_DEST, or GITLAB_SERVER_DOMAIN is not set. Please check your .env file."
  exit 1
fi

# 要求使用者輸入 project ID
read -p "Enter the source project ID from gitlab.com: " SOURCE_PROJECT_ID
read -p "Enter the destination project ID for the self-hosted GitLab server: " DEST_PROJECT_ID

# 匯出變數從 gitlab.com
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN_SOURCE" \
     "https://gitlab.com/api/v4/projects/$SOURCE_PROJECT_ID/variables" > variables.json

# 匯入變數到自架 GitLab Server
cat variables.json | jq -c '.[]' | while read var; do
  key=$(echo $var | jq -r '.key')
  value=$(echo $var | jq -r '.value')
  protected=$(echo $var | jq -r '.protected')
  masked=$(echo $var | jq -r '.masked')
  variable_type=$(echo $var | jq -r '.variable_type')

  curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN_DEST" \
    --data "key=$key" \
    --data "value=$value" \
    --data "protected=$protected" \
    --data "masked=$masked" \
    --data "variable_type=$variable_type" \
    "http://$GITLAB_SERVER_DOMAIN/api/v4/projects/$DEST_PROJECT_ID/variables"
done
