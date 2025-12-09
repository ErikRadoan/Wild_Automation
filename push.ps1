# WILD Automate - Git Push Script
# Commits all changes (except .md files other than README.md) and pushes to GitHub

param(
    [string]$message = ""
)

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "WILD Automate - Git Push" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is available
try {
    $null = git --version
} catch {
    Write-Host "✗ Git not found. Please install Git." -ForegroundColor Red
    exit 1
}

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "✗ Not a git repository!" -ForegroundColor Red
    exit 1
}

# Get commit message
if ($message -eq "") {
    Write-Host "Enter commit message:" -ForegroundColor Yellow
    $message = Read-Host

    if ($message -eq "") {
        Write-Host "✗ Commit message cannot be empty!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Commit message: $message" -ForegroundColor Green
Write-Host ""

# Show what will be committed
Write-Host "Checking for changes..." -ForegroundColor Yellow
$status = git status --short

if ($status -eq $null -or $status -eq "") {
    Write-Host "✓ No changes to commit" -ForegroundColor Green
    Write-Host ""

    # Ask if should push anyway
    $pushAnyway = Read-Host "Push to remote anyway? (y/n)"
    if ($pushAnyway -eq 'y') {
        Write-Host ""
        Write-Host "Pushing to remote..." -ForegroundColor Yellow
        git push

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Pushed successfully!" -ForegroundColor Green
        } else {
            Write-Host "✗ Push failed!" -ForegroundColor Red
            exit 1
        }
    }
    exit 0
}

Write-Host "Changes to be committed:" -ForegroundColor Cyan
Write-Host $status
Write-Host ""

# Stage all changes except .md files (but include README.md)
Write-Host "Staging changes..." -ForegroundColor Yellow

# First, add everything
git add -A

# Then unstage all .md files except README.md
$mdFiles = git diff --cached --name-only | Where-Object { $_ -match '\.md$' -and $_ -notmatch '^README\.md$' }

if ($mdFiles) {
    Write-Host "Excluding documentation files:" -ForegroundColor Yellow
    foreach ($file in $mdFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
        git reset HEAD $file 2>$null
    }
    Write-Host ""
}

# Show what will actually be committed
$stagedFiles = git diff --cached --name-only
if ($stagedFiles -eq $null -or $stagedFiles -eq "") {
    Write-Host "✗ No changes to commit after filtering" -ForegroundColor Red
    exit 1
}

Write-Host "Files to be committed:" -ForegroundColor Green
foreach ($file in $stagedFiles) {
    Write-Host "  ✓ $file" -ForegroundColor Green
}
Write-Host ""

# Confirm
$confirm = Read-Host "Commit and push these changes? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Aborted." -ForegroundColor Yellow
    git reset HEAD . 2>$null
    exit 0
}

# Commit
Write-Host ""
Write-Host "Committing..." -ForegroundColor Yellow
git commit -m "$message"

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Commit failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Committed successfully!" -ForegroundColor Green
Write-Host ""

# Push
Write-Host "Pushing to remote..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Push failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "You may need to:" -ForegroundColor Yellow
    Write-Host "  - Set up remote: git remote add origin <url>" -ForegroundColor White
    Write-Host "  - Set upstream: git push --set-upstream origin main" -ForegroundColor White
    exit 1
}

Write-Host "✓ Pushed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Done! ✨" -ForegroundColor Cyan

