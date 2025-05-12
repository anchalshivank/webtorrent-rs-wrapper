#!/bin/bash
set -euo pipefail

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

# ... [keep your existing confirm() and git_check() functions] ...

# Main workflow
clean_state

# Check working directory
if [[ -n $(git status --porcelain) ]]; then
    # ... [keep your existing working directory checks] ...
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

# ... [rest of your existing script] ...

# Push changes with retry logic
if confirm "Dry run successful. Push changes to remote?"; then
    if ! git push origin release; then
        echo "🔄 Push failed, syncing with remote..."
        clean_state
        git_check pull --rebase origin release
        git_check push origin release
    fi
    
    # ... [rest of your tag pushing logic] ...
fi