# WILD Automate - Build and Release Script
# Commits changes, builds the app, packages it, and creates a GitHub release

param(
    [string]$versionType = "patch",  # major, minor, or patch
    [string]$message = ""
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "WILD Automate - Build & Release" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is available
try {
    $null = git --version
    Write-Host "✓ Git found" -ForegroundColor Green
} catch {
    Write-Host "✗ Git not found. Please install Git." -ForegroundColor Red
    exit 1
}

# Check if Flutter is available
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Host "✓ Flutter found" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found. Please install Flutter." -ForegroundColor Red
    exit 1
}

# Check if GitHub CLI is available
try {
    $null = gh --version
    Write-Host "✓ GitHub CLI found" -ForegroundColor Green
} catch {
    Write-Host "⚠ GitHub CLI not found. Release will not be published automatically." -ForegroundColor Yellow
    Write-Host "  Install from: https://cli.github.com/" -ForegroundColor Gray
    $hasGH = $false
}

if ($null -eq $hasGH) {
    $hasGH = $true
}

Write-Host ""

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "✗ Not a git repository!" -ForegroundColor Red
    exit 1
}

# Get current version from pubspec.yaml
Write-Host "Reading current version..." -ForegroundColor Yellow
$pubspecPath = "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Host "✗ pubspec.yaml not found!" -ForegroundColor Red
    exit 1
}

$pubspecContent = Get-Content $pubspecPath -Raw
$versionMatch = [regex]::Match($pubspecContent, 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')

if (-not $versionMatch.Success) {
    Write-Host "✗ Could not parse version from pubspec.yaml" -ForegroundColor Red
    exit 1
}

$major = [int]$versionMatch.Groups[1].Value
$minor = [int]$versionMatch.Groups[2].Value
$patch = [int]$versionMatch.Groups[3].Value
$currentVersion = "$major.$minor.$patch"

Write-Host "Current version: $currentVersion" -ForegroundColor Cyan
Write-Host ""

# Update version based on type
switch ($versionType.ToLower()) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
    }
    "minor" {
        $minor++
        $patch = 0
    }
    "patch" {
        $patch++
    }
    default {
        Write-Host "✗ Invalid version type. Use: major, minor, or patch" -ForegroundColor Red
        exit 1
    }
}

# Get commit count for build number
$commitCount = git rev-list --count HEAD
$newVersion = "$major.$minor.$patch"
$fullVersion = "$newVersion+$commitCount"

Write-Host "New version: $fullVersion" -ForegroundColor Green
Write-Host ""

# Get commit message if not provided
if ($message -eq "") {
    Write-Host "Enter release notes/commit message:" -ForegroundColor Yellow
    $message = Read-Host

    if ($message -eq "") {
        $message = "Release version $newVersion"
    }
}

Write-Host ""
Write-Host "Release notes: $message" -ForegroundColor Cyan
Write-Host ""

# Confirm
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  1. Update version to $fullVersion" -ForegroundColor White
Write-Host "  2. Commit all changes (except .md files other than README.md)" -ForegroundColor White
Write-Host "  3. Create git tag v$newVersion" -ForegroundColor White
Write-Host "  4. Build Windows release" -ForegroundColor White
Write-Host "  5. Package as ZIP" -ForegroundColor White
if ($hasGH) {
    Write-Host "  6. Create GitHub release" -ForegroundColor White
}
Write-Host ""

$confirm = Read-Host "Continue? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Step 1: Updating version..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Update pubspec.yaml
$newPubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $fullVersion"
Set-Content -Path $pubspecPath -Value $newPubspecContent
Write-Host "✓ Version updated to $fullVersion" -ForegroundColor Green
Write-Host ""

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Step 2: Committing changes..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Stage all changes
git add -A

# Unstage all .md files except README.md
$mdFiles = git diff --cached --name-only | Where-Object { $_ -match '\.md$' -and $_ -notmatch '^README\.md$' }

if ($mdFiles) {
    Write-Host "Excluding documentation files:" -ForegroundColor Yellow
    foreach ($file in $mdFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
        git reset HEAD $file 2>$null
    }
    Write-Host ""
}

# Commit
$commitMessage = "Release v$newVersion - $message"
git commit -m "$commitMessage"

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠ No changes to commit or commit failed" -ForegroundColor Yellow
} else {
    Write-Host "✓ Changes committed" -ForegroundColor Green
}
Write-Host ""

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Step 3: Creating git tag..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Create and push tag
git tag -a "v$newVersion" -m "$message"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Tag v$newVersion created" -ForegroundColor Green
} else {
    Write-Host "⚠ Tag creation failed (may already exist)" -ForegroundColor Yellow
}
Write-Host ""

# Push commits and tags
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
git push
git push --tags

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Pushed to GitHub" -ForegroundColor Green
} else {
    Write-Host "⚠ Push failed" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Step 4: Building Windows release..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Clean previous build
if (Test-Path "build\windows\x64\runner\Release") {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item "build\windows\x64\runner\Release\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Build
Write-Host "Building... (this may take a few minutes)" -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Build completed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Step 5: Packaging..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Create release directory
$releaseDir = "releases"
if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir | Out-Null
}

# Package name
$packageName = "WILD_Automate_v$newVersion"
$zipPath = "$releaseDir\$packageName.zip"

# Remove old zip if exists
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create ZIP
Write-Host "Creating ZIP package..." -ForegroundColor Yellow
$buildPath = "build\windows\x64\runner\Release"

if (-not (Test-Path $buildPath)) {
    Write-Host "✗ Build directory not found!" -ForegroundColor Red
    exit 1
}

# Compress
Compress-Archive -Path "$buildPath\*" -DestinationPath $zipPath -CompressionLevel Optimal

if (Test-Path $zipPath) {
    $zipSize = (Get-Item $zipPath).Length / 1MB
    Write-Host "✓ Package created: $packageName.zip ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create package!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Create GitHub release if GH CLI is available
if ($hasGH) {
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Step 6: Creating GitHub release..." -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""

    # Check if already logged in
    $ghAuth = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠ Not logged into GitHub CLI" -ForegroundColor Yellow
        Write-Host "Please run: gh auth login" -ForegroundColor White
        Write-Host ""
        Write-Host "Release package created but not published." -ForegroundColor Yellow
    } else {
        Write-Host "Creating GitHub release..." -ForegroundColor Yellow

        # Create release
        gh release create "v$newVersion" `
            $zipPath `
            --title "WILD Automate v$newVersion" `
            --notes "$message" `
            --latest

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ GitHub release created successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠ Failed to create GitHub release" -ForegroundColor Yellow
            Write-Host "You can manually create it at: https://github.com/your-org/wild_automation/releases/new" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✨ Release Complete! ✨" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Version: v$newVersion" -ForegroundColor Green
Write-Host "Package: $zipPath" -ForegroundColor Green
Write-Host ""

if ($hasGH -and $LASTEXITCODE -eq 0) {
    Write-Host "✓ Release published to GitHub!" -ForegroundColor Green
    Write-Host ""
    Write-Host "View release: gh release view v$newVersion --web" -ForegroundColor Cyan
} else {
    Write-Host "To publish manually:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://github.com/your-org/wild_automation/releases/new" -ForegroundColor White
    Write-Host "  2. Select tag: v$newVersion" -ForegroundColor White
    Write-Host "  3. Upload: $zipPath" -ForegroundColor White
}

Write-Host ""
Write-Host "Done! 🚀" -ForegroundColor Cyan

