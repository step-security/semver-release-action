#!/bin/sh -l

set -u

# validate subscription status
REPO_PRIVATE=$(jq -r '.repository.private | tostring' "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
UPSTREAM="k-phoen/semver-release-action"
ACTION_REPO="${GITHUB_ACTION_REPOSITORY:-}"
DOCS_URL="https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions"

echo ""
echo -e "\033[1;36mStepSecurity Maintained Action\033[0m"
echo "Secure drop-in replacement for $UPSTREAM"
if [ "$REPO_PRIVATE" = "false" ]; then
  echo -e "\033[32m✓ Free for public repositories\033[0m"
fi
echo -e "\033[36mLearn more:\033[0m $DOCS_URL"
echo ""

if [ "$REPO_PRIVATE" != "false" ]; then
  SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

  if [ "$SERVER_URL" != "https://github.com" ]; then
    BODY=$(printf '{"action":"%s","ghes_server":"%s"}' "$ACTION_REPO" "$SERVER_URL")
  else
    BODY=$(printf '{"action":"%s"}' "$ACTION_REPO")
  fi

  API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/maintained-actions-subscription"

  RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API_URL" -o /dev/null) && CURL_EXIT_CODE=0 || CURL_EXIT_CODE=$?

  if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Timeout or API not reachable. Continuing to next step."
  elif [ "$RESPONSE" = "403" ]; then
    echo -e "::error::\033[1;31mThis action requires a StepSecurity subscription for private repositories.\033[0m"
    echo -e "::error::\033[31mLearn how to enable a subscription: $DOCS_URL\033[0m"
    exit 1
  fi
fi

if [ -z "${GITHUB_TOKEN}" ]
then
    echo "The GITHUB_TOKEN environment variable is not defined."
    exit 1
fi

RELEASE_BRANCH="$1"
RELEASE_STRATEGY="$2"
NEXT_TAG="$3"
TAG_FORMAT="$4"

echo "::debug::Executing bumper guard release_branch=${RELEASE_BRANCH},github_event_path=${GITHUB_EVENT_PATH}"
/bumper guard "${RELEASE_BRANCH}" "${GITHUB_EVENT_PATH}"
if [ $? -eq 78 ]
then
    echo "::debug::Guard returned a neutral code, stopping the execution."
    exit 0
fi

if [ -z "${NEXT_TAG}" ]
then
    echo "::debug::Executing bumper latest-tag github_repository=${GITHUB_REPOSITORY}"
    LATEST_TAG=$(/bumper latest-tag "${GITHUB_REPOSITORY}" "${GITHUB_TOKEN}")

    echo "::debug::Executing bumper increment github_event_path=${GITHUB_EVENT_PATH}"
    INCREMENT=$(/bumper increment "${GITHUB_EVENT_PATH}")

    echo "::debug::Executing bumper semver latest_tag=${LATEST_TAG},increment=${INCREMENT}"
    NEXT_TAG=$(/bumper semver "${LATEST_TAG}" "${INCREMENT}" "${TAG_FORMAT}")
fi

echo "::debug::Executing bumper release github_repository=${GITHUB_REPOSITORY},github_sha=${GITHUB_SHA},next_tag=${NEXT_TAG},strategy=${RELEASE_STRATEGY}"
/bumper release --strategy "${RELEASE_STRATEGY}" "${GITHUB_REPOSITORY}" "${GITHUB_SHA}" "${NEXT_TAG}" "${GITHUB_TOKEN}"

printf 'tag=%s\n' "${NEXT_TAG}" >> "${GITHUB_OUTPUT}"
