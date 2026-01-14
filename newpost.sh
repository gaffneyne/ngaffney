#!/bin/bash

# Prompt for the title
read -p "Enter post title: " title

# Get today's date
today=$(date +%Y-%m-%d)
shortdate=$(date +%m-%d-%y)

# Create a safe slug (lowercase, dashes)
slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')

# Set filename and path
filename="recent/$today-$slug.md"

# Image base name (you can customize how the image name is generated)
imgname="${shortdate}_$(echo $slug | tr '-' '_')"

# Create markdown content
cat > "$filename" <<EOF
---
title: $title
date: $today
layout: post.njk
---

<img srcset="https://ngaffney.net/images/recent/REPLACE-1000px.jpg 1x, https://ngaffney.net/images/recent/REPLACE-2000px.jpg 2x" src="https://ngaffney.net/images/recent/REPLACE-1000px.jpg" alt="$title" />
EOF

echo "✅ Created: $filename"

# Optional: open in default editor (comment out if you don't want this)
open "$filename"
