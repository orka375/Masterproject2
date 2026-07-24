#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 \"commit message\""
    exit 1
fi

COMMIT_MSG="$1"

echo "Commit message: $COMMIT_MSG"

SUBMODULES=$(git submodule foreach --quiet 'echo $path')

for SUBMODULE in $SUBMODULES; do

    # Skip Robots submodule
    if [ "$SUBMODULE" = "20_ROS/src/Robots" ]; then
        echo "Skipping $SUBMODULE"
        continue
    fi

    echo "===================================="
    echo "Processing submodule: $SUBMODULE"
    echo "===================================="

    cd "$SUBMODULE"

    echo "Checking out main..."
    git checkout main

    echo "Pulling latest changes..."
    git pull origin main

    echo "Adding changes..."
    git add .

    # Check if there is anything to commit
    if git diff --cached --quiet; then
        echo "No changes in $SUBMODULE, skipping."
    else
        echo "Committing..."
        git commit -m "$COMMIT_MSG"

        echo "Pushing..."
        git push origin main

        echo "Done: $SUBMODULE"
    fi

    cd - >/dev/null

done

echo "===================================="
echo "Updating parent repository"
echo "===================================="

git add .

if git diff --cached --quiet; then
    echo "No submodule pointer changes."
else
    git commit -m "$COMMIT_MSG"
    git push
fi

echo "All submodules processed."