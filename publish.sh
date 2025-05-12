#!/bin/bash
set -euo pipefail

# Function to ask for confirmation
confirm() {
    read -p "$1 (y/n) " choice
    case "$choice" in
        y|Y ) return 0;;
        * ) return 1;;
    esac
}

# Check if working directory is clean
if [[ -n $(git status --porcelain) ]]; then
    echo "Working directory not clean. Please commit or stash changes first."
    git status
    if ! confirm "Do you want to commit all changes?"; then
        exit 1
    fi
    git add .
    git commit -m "chore: preparing for release"
fi

# Ensure we're on release branch
if [[ $(git branch --show-current) != "release" ]]; then
    echo "Not on release branch. Switching..."
    git checkout release
fi

# Sync with main branch
echo "Syncing with main branch..."
git fetch origin main:main
git merge main --no-ff -m "chore: merge main into release"

# Version bump
PS3="Select version bump type: "
select bump_type in major minor patch; do
    case $bump_type in
        major|minor|patch )
            echo "Bumping $bump_type version..."
            cargo set-version --bump $bump_type
            VERSION=$(cargo pkgid | sed 's/.*#//')
            git commit -am "chore: bump version to $VERSION"
            break
            ;;
        * )
            echo "Invalid option. Please select 1-3."
            ;;
    esac
done

# Dry run
echo "Running cargo publish dry-run..."
if ! cargo publish --dry-run; then
    echo "❌ Dry run failed. Please fix issues before publishing."
    exit 1
fi

# Push changes
if confirm "Dry run successful. Push changes to remote?"; then
    git push origin release
    git tag v$VERSION
    git push origin v$VERSION
    echo "✅ Changes pushed. Version $VERSION is ready for publishing."
fi