#!/bin/bash

# Optional Script to Remove Chat Components from Contoso Web
# Run this on the EC2 instance to completely remove chat UI and functionality
# Usage: bash disable-chat.sh

set -e

DEPLOY_DIR="/opt/contoso-web"

echo "========================================="
echo "Contoso Web - Chat Component Remover"
echo "========================================="
echo ""
echo "WARNING: This script will modify source code."
echo "It will:"
echo "  - Comment out chat components"
echo "  - Disable chat API routes"
echo "  - Remove chat-specific CSS/styling"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

cd "$DEPLOY_DIR"

# Create backup
echo "Creating backup of src directory..."
if [ ! -d "src.backup" ]; then
    cp -r src src.backup
    echo "Backup created: src.backup"
else
    echo "Backup already exists: src.backup"
fi

echo ""
echo "Step 1: Disabling chat API routes..."

# Find and rename chat API directory
if [ -d "src/pages/api/chat" ]; then
    mv "src/pages/api/chat" "src/pages/api/chat.disabled"
    echo "✓ Chat API routes disabled: src/pages/api/chat → chat.disabled"
else
    echo "⚠ Chat API routes not found (already disabled?)"
fi

echo ""
echo "Step 2: Removing chat components from imports..."

# Find all TypeScript/JavaScript files that import chat components
find src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" \) | while read file; do
    if grep -q "import.*Chat" "$file" || grep -q "from.*chat" "$file"; then
        echo "  Modifying: $file"
        # Comment out chat imports
        sed -i 's/^import.*Chat.*from/#import Chat from/g' "$file"
        sed -i 's/^import.*from.*chat/#import from chat/g' "$file"
    fi
done

echo "✓ Chat component imports commented out"

echo ""
echo "Step 3: Removing chat component usage..."

# Comment out Chat component tags in JSX/TSX files
find src -type f \( -name "*.tsx" -o -name "*.jsx" \) | while read file; do
    if grep -q "<Chat" "$file"; then
        echo "  Cleaning: $file"
        # Comment out Chat component usage
        sed -i 's/<Chat/{\/* <Chat/g' "$file"
        sed -i 's/<\/Chat/\/Chat> *\/}/g' "$file"
    fi
done

echo "✓ Chat component usage commented out"

echo ""
echo "Step 4: Checking for chat-related environment variables..."

# Display environment variables
echo "Current environment variables:"
env | grep -i "CONTOSO\|PROMPTFLOW\|VISUAL" || echo "  (no chat-related variables found)"

echo ""
echo "Step 5: Rebuilding application..."

echo "  Installing dependencies..."
npm ci --silent

echo "  Building Next.js application..."
npm run build 2>&1 | tail -n 5

echo ""
echo "✓ Build completed"

echo ""
echo "Step 6: Restarting application..."

# Restart with PM2
pm2 restart contoso-web --no-save
sleep 3

# Check status
echo "Application status:"
pm2 status contoso-web

echo ""
echo "========================================="
echo "Chat components removal completed!"
echo "========================================="
echo ""
echo "Changes made:"
echo "  ✓ Chat API routes disabled"
echo "  ✓ Chat component imports commented out"
echo "  ✓ Chat component usage removed from UI"
echo "  ✓ Application rebuilt and restarted"
echo ""
echo "Backup location: $DEPLOY_DIR/src.backup"
echo ""
echo "To revert these changes:"
echo "  1. rm -rf src"
echo "  2. cp -r src.backup src"
echo "  3. npm run build"
echo "  4. pm2 restart contoso-web"
echo ""
echo "Application logs:"
echo "  PM2: pm2 logs contoso-web"
echo "  App output: tail -f /opt/contoso-web/logs/out.log"
echo ""
echo "========================================="
