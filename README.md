# snowmate-gitlab-runner
This is a Bash script for running Snowmate's tests in GitLab's CI/CD.


## How to Add it to Your CI/CD ##

```yml
stages:
  - run_snowmate_tests

variables:
  PROJECT_ID: "" # Replace this with the project_id you have created on our website.
  PROJECT_PATH: "." # If this repo is not a monorepo, leave it as ".", otherwise, replace it with the relative path of the relevant service, e.g., "worker".

run-snowmate-tests:
  stage: run_snowmate_tests
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
  image: python:3.10
  script:
    ##### Setting some variables #####
    - FEATURE_PROJECT_PATH=$(pwd)
    - TEMP_DIR=$(mktemp -d)

    - SNOWMATE_CI_SCRIPT_URL="git@github.com:snowmate/snowmate-gitlab-runner.git"
    - BASH_SCRIPT_PATH="$TEMP_DIR/snowmate-gitlab-runner/gitlab-ci-runner.sh"

    ##### Fetching Snowmate's Bash script for running tests #####
    - git clone $SNOWMATE_CI_SCRIPT_URL $TEMP_DIR
    - "$BASH_SCRIPT_PATH" $PROJECT_ID $PROJECT_PATH $TEMP_DIR $FEATURE_PROJECT_PATH
```

Please note that in order to run this in your CI, you need to create three variables:

1. SNOWMATE_CLIENT_ID
2. SNOWMATE_SECRET_KEY
3. SNOWMATE_GITLAB_GROUP_TOKEN

- SNOWMATE_CLIENT_ID & SNOWMATE_SECRET_KEY
    You must create and add both variables to your GitLab project.
    Instructions on how to add variables to GitLab can be found here.
    If you don't have credentials yet, please follow our documentation: Create a New Snowmate Project.



- SNOWMATE_GITLAB_GROUP_TOKEN
    Snowmate requires this token to successfully create a comment on GitLab's pull request, like so:
    []
    Be sure to follow our documentation for more instructions on how to create a group access token.
    If, for some reason, you are unable to create this token, you can still enjoy our product without receiving the comment.


**Happy Integrating!**