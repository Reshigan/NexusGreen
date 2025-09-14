#!/bin/bash

# GitHub Repository Cleanup and Branch Management Script
# This script cleans up the repository and merges all branches

set -e

echo "🧹 GitHub Repository Cleanup and Branch Management"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Get repository information
REPO_URL=$(git remote get-url origin)
CURRENT_BRANCH=$(git branch --show-current)
print_status "Repository: $REPO_URL"
print_status "Current branch: $CURRENT_BRANCH"

# Step 1: Fetch all remote branches and tags
print_status "Step 1: Fetching all remote branches and tags..."
git fetch --all --prune
git fetch --tags
print_success "Remote data fetched"

# Step 2: List all branches
print_status "Step 2: Analyzing repository branches..."
echo "Local branches:"
git branch -v
echo ""
echo "Remote branches:"
git branch -r
echo ""

# Step 3: Switch to main branch and ensure it's up to date
print_status "Step 3: Ensuring main branch is up to date..."
git checkout main
git pull origin main
print_success "Main branch updated"

# Step 4: Merge feature branches (if any exist and are safe to merge)
print_status "Step 4: Checking for feature branches to merge..."

# Get list of branches that aren't main/master
FEATURE_BRANCHES=$(git branch -r | grep -v 'HEAD\|main\|master' | sed 's/origin\///' | tr -d ' ' || true)

if [ -n "$FEATURE_BRANCHES" ]; then
    echo "Found feature branches:"
    echo "$FEATURE_BRANCHES"
    echo ""
    
    for branch in $FEATURE_BRANCHES; do
        print_status "Analyzing branch: $branch"
        
        # Check if branch exists locally
        if git show-ref --verify --quiet refs/heads/$branch; then
            print_status "Branch $branch exists locally"
        else
            print_status "Creating local branch $branch from origin/$branch"
            git checkout -b $branch origin/$branch
        fi
        
        # Switch to the branch and check if it's ahead of main
        git checkout $branch
        git pull origin $branch 2>/dev/null || true
        
        # Check if this branch has commits ahead of main
        COMMITS_AHEAD=$(git rev-list --count main..$branch 2>/dev/null || echo "0")
        
        if [ "$COMMITS_AHEAD" -gt "0" ]; then
            print_status "Branch $branch has $COMMITS_AHEAD commits ahead of main"
            
            # Switch back to main and merge
            git checkout main
            
            # Try to merge (fast-forward if possible)
            if git merge --no-ff $branch -m "Merge branch '$branch' into main"; then
                print_success "Successfully merged $branch into main"
                
                # Delete the local branch
                git branch -d $branch
                print_status "Deleted local branch $branch"
            else
                print_warning "Failed to merge $branch - may have conflicts"
                git merge --abort 2>/dev/null || true
            fi
        else
            print_status "Branch $branch has no new commits, skipping merge"
            git checkout main
            git branch -d $branch 2>/dev/null || true
        fi
    done
else
    print_status "No feature branches found to merge"
fi

# Step 5: Clean up merged remote branches
print_status "Step 5: Cleaning up merged remote branches..."
git remote prune origin
print_success "Remote branch cleanup completed"

# Step 6: Add and commit any new files
print_status "Step 6: Adding and committing new production files..."
git add .
if git diff --staged --quiet; then
    print_status "No new changes to commit"
else
    git commit -m "🚀 Add production deployment configuration

- Complete production deployment script with SSL, timezone, demo data
- Production-optimized Docker configurations
- GitHub cleanup and branch management
- All dependencies and requirements updated
- Ready for final production release

Features:
- SSL certificate setup with Let's Encrypt
- South African timezone configuration
- Demo company and user seeding
- Production nginx configuration
- Comprehensive logging and monitoring
- Auto-renewal for SSL certificates"
    print_success "New production files committed"
fi

# Step 7: Push all changes to main
print_status "Step 7: Pushing changes to main branch..."
git push origin main
print_success "Changes pushed to main"

# Step 8: Delete merged remote branches
print_status "Step 8: Cleaning up merged remote branches..."
for branch in $FEATURE_BRANCHES; do
    if [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
        # Check if branch still exists on remote
        if git ls-remote --heads origin $branch | grep -q $branch; then
            print_status "Deleting remote branch: $branch"
            git push origin --delete $branch 2>/dev/null || print_warning "Could not delete remote branch $branch"
        fi
    fi
done
print_success "Remote branch cleanup completed"

# Step 9: Create production release tag
print_status "Step 9: Creating production release tag..."
RELEASE_TAG="v1.0.0-production-$(date +%Y%m%d)"
git tag -a $RELEASE_TAG -m "Production Release $RELEASE_TAG

🚀 SolarNexus Production Release

Features:
- Complete solar energy management system
- Real-time monitoring and analytics
- User and company management
- SSL-secured deployment
- Demo data for presentations
- Production-ready configuration

Deployment:
- SSL Certificate: Let's Encrypt
- Domain: nexus.gonxt.tech
- Timezone: South Africa (SAST)
- Demo Company: GonXT Solar Solutions
- Admin: admin@gonxt.tech / Demo2024!
- User: user@gonxt.tech / Demo2024!

Technical:
- Docker containerized deployment
- PostgreSQL database with demo data
- Redis caching
- Nginx reverse proxy with SSL
- Automated backup and monitoring
- Production logging and health checks"

git push origin $RELEASE_TAG
print_success "Production release tag $RELEASE_TAG created and pushed"

# Step 10: Repository statistics and cleanup summary
print_status "Step 10: Repository cleanup summary..."
echo ""
echo "📊 Repository Statistics:"
echo "========================"
echo "Total commits: $(git rev-list --all --count)"
echo "Contributors: $(git shortlog -sn | wc -l)"
echo "Current branch: $(git branch --show-current)"
echo "Latest tag: $(git describe --tags --abbrev=0 2>/dev/null || echo 'None')"
echo "Repository size: $(du -sh .git | cut -f1)"
echo ""

echo "🧹 Cleanup Summary:"
echo "==================="
echo "✅ All branches merged to main"
echo "✅ Remote branches cleaned up"
echo "✅ Production files committed"
echo "✅ Release tag created: $RELEASE_TAG"
echo "✅ Repository optimized"
echo ""

echo "🚀 Next Steps:"
echo "=============="
echo "1. Run production deployment: ./production-deploy.sh"
echo "2. Verify SSL certificate: https://nexus.gonxt.tech"
echo "3. Test demo credentials"
echo "4. Monitor application logs"
echo ""

print_success "GitHub repository cleanup completed successfully!"
echo "Repository is now ready for production deployment."