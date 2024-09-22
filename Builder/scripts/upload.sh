#!/bin/bash

# Check if a file argument is provided
if [[ "$#" == '0' ]]; then
    echo -e 'ERROR: No File Specified!' && exit 1
fi

# Store the file path, preserving spaces
# $1 is the first command-line argument
FILE="$1"

# Query GoFile API to find the best server for upload
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

# Upload the file to GoFile
# Use jq to parse JSON response and extract the download page URL
LINK=$(curl -# -F "file=@$FILE" "https://${SERVER}.gofile.io/uploadFile" | jq -r '.data|.downloadPage') 2>&1

# Display the download link
echo "Download link: $LINK"

# Add the link to GITHUB_ENV
# Append the link to the special environment variable file
echo "DOWNLOAD_LINK=$LINK" >> "$GITHUB_ENV"

# Print a blank line for better readability
echo
