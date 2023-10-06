##### Setting some more necessary variables #####
export PROJECT_ID=$1
export PROJECT_PATH=$2
export TEMP_DIR=$3
export FEATURE_PROJECT_PATH=$4
export SNOWMATE_REPORT_FILE_PATH="/tmp/snowmate_result.md"
export MERGE_REQUEST_COMMENT_API_URL="https://gitlab.com/api/v4/projects/$CI_MERGE_REQUEST_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes"

if [ -z "$SNOWMATE_APP_URL" ]; then
  export SNOWMATE_APP_URL="https://app.snowmate.io"
fi

if [ -z "$SNOWMATE_AUTH_URL" ]; then
  export SNOWMATE_AUTH_URL="https://auth.snowmate.io"
fi

if [ -z "$SNOWMATE_API_URL" ]; then
  export SNOWMATE_API_URL="https://api.snowmate.io"
fi

if [ -z "$SNOWMATE_PYPI_URL" ]; then
  export SNOWMATE_PYPI_URL="https://pypi.snowmate.io/simple"
fi

##### Installing requirements #####
pip3 install -r requirements.txt

##### Installing snowmate_runner #####
pip3 install -i "https://${SNOWMATE_CLIENT_ID}:${SNOWMATE_SECRET_KEY}@pypi.dev.snowmate.io/simple" -U snowmate_runner

##### Cloning previous branch #####
cd $TEMP_DIR
git clone -b $CI_MERGE_REQUEST_TARGET_BRANCH_NAME   $CI_REPOSITORY_URL
cd $CI_PROJECT_NAME
export BASELINE_PROJECT_PATH=$(pwd)
git checkout $CI_MERGE_REQUEST_TARGET_BRANCH_SHA

##### Running snowmate's tests #####
cd $FEATURE_PROJECT_PATH
set +e # Disable exit on error
snowmate_runner run --project-id $PROJECT_ID --client-id $SNOWMATE_CLIENT_ID --secret-key $SNOWMATE_SECRET_KEY --workflow-run-id $CI_PIPELINE_ID --cloned-repo-dir $BASELINE_PROJECT_PATH/$PROJECT_PATH --project-root-path $FEATURE_PROJECT_PATH/$PROJECT_PATH --details-url $SNOWMATE_APP_URL/regressions/$PROJECT_ID/$CI_PIPELINE_ID --pull-request-number $CI_MERGE_REQUEST_ID --api-url $SNOWMATE_API_URL --auth-url $SNOWMATE_AUTH_URL --pypi-url $SNOWMATE_PYPI_URL; snowmate_runner_status=$?
set -e # Re-enable exit on error

##### Create the pull request comment #####
if [ -z "$SNOWMATE_GITLAB_GROUP_TOKEN" ]; then
    if [ -e $SNOWMATE_REPORT_FILE_PATH ]; then
        apt update
        apt-get install jq --assume-yes
        markdown_content=$(cat $SNOWMATE_REPORT_FILE_PATH | jq -s -R .)
        curl --location --request POST "$MERGE_REQUEST_COMMENT_API_URL" --header "PRIVATE-TOKEN: $SNOWMATE_GITLAB_GROUP_TOKEN" --header "Content-Type: application/json" --data-raw "{ \"body\": $markdown_content }"
    else
        echo "Snowmate result file was not created, can not create a comment on the pull request"
    fi
fi

else
    echo "SNOWMATE_GITLAB_GROUP_TOKEN does not exist, can not create a comment on the pull request"

exit $snowmate_runner_status