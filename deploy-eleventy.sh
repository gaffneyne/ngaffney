#!/bin/bash

# CONFIGURE THESE
USER="your-username"
HOST="your-host.com"
REMOTE_DIR="/path/to/webroot/eleventy"

# Deploy via rsync
echo "Deploying to $USER@$HOST:$REMOTE_DIR..."
rsync -avz --delete output/ "$USER@$HOST:$REMOTE_DIR"

echo "✅ Deploy complete. Visit: https://your-host.com/eleventy/"
