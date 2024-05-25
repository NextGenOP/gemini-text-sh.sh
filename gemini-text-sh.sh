#!/bin/sh
set -eu
if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is not installed. Please install jq to proceed."
  exit 1
fi

if ! command -v curl > /dev/null 2>&1; then
  echo "Error: curl is not installed. Please install curl to proceed."
  exit 1
fi

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
  usage
fi

ARGUMENT="$1"

# set GEMINI_API_KEY in env
API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GEMINI_API_KEY"
API_DATA=$(cat <<EOF
{
  "contents": [{
    "parts":[{
      "text": "Convert this text to a command that works in a BASH shell, return the command with comment referring to https://explainshell.com/explain?cmd=[URL ENCODED COMMAND] only. Convert this ${ARGUMENT}"
    }]
  }]
}
EOF
)

RESPONSE=$(curl -s -H 'Content-Type: application/json' -X POST -d "$API_DATA" "$API_URL")

# Parse the JSON
RETURNED_COMMAND=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text')

if [ "$RETURNED_COMMAND" = "null" ] || [ -z "$RETURNED_COMMAND" ]; then
  echo "Error: No command returned from the API."
  exit 1
fi

echo "$RETURNED_COMMAND"

if [ $EXECUTE_COMMAND -eq 1 ]; then
  echo "Do you want to execute the command? (yes/no)"
  read CONFIRMATION
  if [ "$CONFIRMATION" = "yes" ]; then
    echo "Executing command..."
    sh -c "$RETURNED_COMMAND"
  else
    echo "Command execution aborted."
  fi
fi
