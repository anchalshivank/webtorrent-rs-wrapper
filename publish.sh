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

# Function to clean up failed rebase/merge
clean_state() {
    echo "⚠️ Cleaning up any failed git state..."
    git merge --abort 2>/dev/null || true
    git rebase --abort 2>/dev/null || true
    rm -fr ".git/rebase-merge" ".git/rebase-apply" ".git/MERGE_HEAD"
}

# Function to handle merge conflicts
resolve_conflicts() {
    echo "⏳ Merge conflict detected. Attempting to resolve..."
    
    # For Cargo.lock conflicts, always take the remote version
    if [ -f "Cargo.lock" ] && git diff --name-only --diff-filter=U | grep -q "Cargo.lock"; then
        echo "🔧 Resolving Cargo.lock conflict by keeping remote version..."
        git checkout --theirs Cargo.lock
        cargo generate-lockfile
        git add Cargo.lock
    fi
    
    # For Cargo.toml conflicts, require manual resolution
    if git diff --name-only --diff-filter=U | grep -q "Cargo.toml"; then
        echo "❌ Cargo.toml has conflicts that require manual resolution:"
        git diff Cargo.toml
        echo "Please resolve these conflicts manually and run:"
        echo "1. git add Cargo.toml"
        echo "2. git rebase --continue"
        echo "3. Run this script again"
        exit 1
    fi
    
    # Continue the rebase if all conflicts resolved
    if [ -z "$(git diff --name-only --diff-filter=U)" ]; then
        git rebase --continue
        return 0
    else
        echo "❌ Unresolved conflicts in:"
        git diff --name-only --diff-filter=U
        exit 1
    fi
}

# Main workflow
clean_state

# Check working directory
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
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "release" ]]; then
    echo "Not on release branch. Switching..."
    git_check checkout release
fi

# Sync with remote
echo "🔄 Syncing with remote..."
git_check fetch --all --prune

# Update release branch
if ! git merge --ff-only origin/release; then
    echo "🔀 Local branch diverged. Attempting rebase..."
    clean_state
    
    # Attempt rebase with conflict handling
    if ! git rebase origin/release; then
        resolve_conflicts
        exit $?
    fi
fi

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
            git add Cargo.toml Cargo.lock
            git commit -m "chore: bump version to $VERSION"
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
        echo "🔄 Push failed, syncing with remote..."
        clean_state
        git_check pull --rebase origin release
        git_check push origin release
    fi
    
    echo "Creating and pushing tag..."
    git tag -a "v$VERSION" -m "Version $VERSION"
    git push origin "v$VERSION"
    
    echo "✅ Successfully pushed version $VERSION to remote"
    echo "🚀 Ready to publish to crates.io!"
fi