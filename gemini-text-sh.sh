#!/bin/sh
set -eu

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_dependency() {
  if ! command -v "$1" > /dev/null 2>&1; then
    echo "${RED}Error: $1 is not installed. Please install $1 to proceed.${NC}" >&2
    exit 1
  fi
}

check_dependency "jq"
check_dependency "curl"

# help
help() {
  echo "Usage: $0 [-x] <argument>"
  echo "  -x  Execute the returned command"
  exit 1
}

EXECUTE_COMMAND=0

while getopts ":x" opt; do
  case ${opt} in
    x )
      EXECUTE_COMMAND=1
      ;;
    \? )
      help
      ;;
  esac
done
shift $((OPTIND -1))

# Check if the argument is provided
if [ $# -eq 0 ]; then
  echo "${RED}Error: Argument is required.${NC}" >&2
  help
fi

ARGUMENT="$1"

# set GEMINI_API_KEY in env
API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent?key=$GEMINI_API_KEY"
API_DATA=$(cat <<EOF
{
  "contents": [{
    "parts":[{
      "text": "Convert this text into POSIX shell, return only the command in plain text. Convert this ${ARGUMENT}"
    }]
  }]
}
EOF
)

RESPONSE=$(curl -s -H 'Content-Type: application/json' -X POST -d "$API_DATA" "$API_URL" || { echo "${RED}Error: Failed to retrieve response from API.${NC}" >&2; exit 1; })

# Parse the JSON
RETURNED_COMMAND=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text' || { echo "${RED}Error: Failed to parse JSON response.\nResponse:$RESPONSE${NC}" >&2; exit 1; })

if [ "$RETURNED_COMMAND" = "null" ] || [ -z "$RETURNED_COMMAND" ]; then
  echo "${RED}Error: No command returned from the API.${NC}"
  exit 1
fi

echo "${GREEN}$RETURNED_COMMAND${NC}"

if [ $EXECUTE_COMMAND -eq 1 ]; then
  echo -n "${YELLOW}Do you want to execute the command? (y/n)${NC}"
  read -r CONFIRMATION
  if [ "$CONFIRMATION" = "y" ]; then
    echo "${GREEN}Executing command...${NC}"
    $RETURNED_COMMAND
  else
    echo "${YELLOW}Command execution aborted.${NC}"
  fi
fi
