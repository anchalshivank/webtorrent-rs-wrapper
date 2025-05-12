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

# Function to check if git operation succeeded
git_check() {
    if ! git "$@"; then
        echo "❌ Git command failed: git $*"
        exit 1
    fi
}

# Check if working directory is clean
if [[ -n $(git status --porcelain) ]]; then
    echo "Working directory not clean. Please commit or stash changes first."
    git status
    if ! confirm "Do you want to commit all changes?"; then
        exit 1
    fi
    git_check add .
    git_check commit -m "chore: preparing for release"
fi

# Ensure we're on release branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "release" ]]; then
    echo "Not on release branch. Switching..."
    git_check checkout release || {
        echo "❌ Failed to checkout release branch"
        exit 1
    }
fi

# Sync with remote
echo "Syncing with remote..."
git_check fetch --all --prune

# Update release branch from remote
if ! git merge --ff-only origin/release; then
    echo "❌ Local branch has diverged from remote. Attempting rebase..."
    git_check rebase origin/release
fi

# Sync with main branch
echo "Syncing with main branch..."
git_check merge origin/main --no-ff -m "chore: merge main into release"

# Version bump
PS3="Select version bump type: "
select bump_type in major minor patch; do
    case $bump_type in
        major|minor|patch )
            echo "Bumping $bump_type version..."
            if ! cargo set-version --bump "$bump_type"; then
                echo "❌ Failed to bump version"
                exit 1
            fi
            VERSION=$(cargo pkgid | sed 's/.*#//')
            git_check add Cargo.toml Cargo.lock
            git_check commit -m "chore: bump version to $VERSION"
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
    echo "Pushing to remote..."
    if ! git push origin release; then
        echo "⚠️ Push failed, attempting to pull and rebase..."
        git_check pull --rebase origin release
        git_check push origin release
    fi
    
    echo "Creating and pushing tag..."
    git_check tag -a "v$VERSION" -m "Version $VERSION"
    git_check push origin "v$VERSION"
    
    echo "✅ Successfully pushed version $VERSION to remote"
    echo "🚀 Ready to publish to crates.io!"
fi