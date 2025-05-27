#!/bin/bash
# build_and_install.sh - Build and optionally install cdto (Production Version)

set -e  # Exit on error

# Configuration
PROJECT_DIR="/Users/mtvogel/Documents/Github-Repos/cdto/cd to ..."
APP_NAME="cd to.app"
BUILD_CONFIG="Release"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building cdto (Production Release)...${NC}"

# Ensure we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"
    echo "Please update the PROJECT_DIR variable in this script."
    exit 1
fi

cd "$PROJECT_DIR"

# Check if project file exists
if [ ! -f "cd to.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Xcode project not found in current directory${NC}"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
xcodebuild -project "cd to.xcodeproj" -target "cd to" -configuration "$BUILD_CONFIG" clean > /dev/null 2>&1

# Build the project
echo -e "${YELLOW}⚙️  Building $BUILD_CONFIG configuration...${NC}"
if xcodebuild -project "cd to.xcodeproj" -target "cd to" -configuration "$BUILD_CONFIG" build > build.log 2>&1; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed!${NC}"
    echo "Check build.log for details:"
    tail -20 build.log
    exit 1
fi

# Check if the app was built
BUILT_APP_PATH="./build/$BUILD_CONFIG/$APP_NAME"
if [ ! -d "$BUILT_APP_PATH" ]; then
    echo -e "${RED}❌ Built app not found at expected location: $BUILT_APP_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}📱 Built app location: $BUILT_APP_PATH${NC}"

# Get app info
APP_VERSION=$(defaults read "$BUILT_APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
echo -e "${BLUE}📋 App version: $APP_VERSION${NC}"

# Show what's new in this version
echo -e "${BLUE}🎆 What's New in This Version:${NC}"
echo -e "${GREEN}• Fixed double Terminal window opening issue${NC}"
echo -e "${GREEN}• Fixed theme/profile not being applied correctly${NC}"
echo -e "${GREEN}• Enhanced auto-close detection with better heuristics${NC}"
echo -e "${GREEN}• Automatic Terminal profile detection (no manual config needed)${NC}"
echo -e "${GREEN}• Improved reliability across different Terminal states${NC}"
echo -e "${GREEN}• Maintains speed and shell-agnostic benefits${NC}"

# Optional installation
echo ""
read -p "$(echo -e "${YELLOW}📥 Install to Applications folder? (y/n): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}📱 Installing to Applications...${NC}"
    
    # Remove existing version if it exists
    if [ -d "/Applications/$APP_NAME" ]; then
        echo -e "${YELLOW}🔄 Removing existing version...${NC}"
        rm -rf "/Applications/$APP_NAME"
    fi
    
    # Copy new version
    cp -R "$BUILT_APP_PATH" "/Applications/"
    
    if [ -d "/Applications/$APP_NAME" ]; then
        echo -e "${GREEN}✅ Successfully installed to /Applications/$APP_NAME${NC}"
        echo -e "${BLUE}📌 You can now drag it to your Finder toolbar!${NC}"
        
        # Offer to open Applications folder
        echo ""
        read -p "$(echo -e "${YELLOW}📂 Open Applications folder? (y/n): ${NC}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open /Applications
        fi
    else
        echo -e "${RED}❌ Installation failed${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}📋 App built but not installed. You can find it at:${NC}"
    echo -e "${BLUE}   $BUILT_APP_PATH${NC}"
fi

# Clean up build log
rm -f build.log

echo ""
echo -e "${GREEN}🎉 Production build complete!${NC}"
echo ""
echo -e "${BLUE}💡 Usage Instructions:${NC}"
echo -e "${BLUE}   1. Drag 'cd to.app' from Applications to your Finder toolbar${NC}"
echo -e "${BLUE}   2. Navigate to any folder in Finder${NC}"
echo -e "${BLUE}   3. Click the 'cd to' button to open Terminal in that directory${NC}"
echo ""
echo -e "${BLUE}🔧 Optional Configuration:${NC}"
echo -e "${BLUE}   • Enable auto-close: defaults write name.tuley.jay.cd-to cdto-close-default-window -bool true${NC}"
echo -e "${BLUE}   • Set custom profile: defaults write name.tuley.jay.cd-to cdto-new-window-setting -string \"ProfileName\"${NC}"
echo -e "${BLUE}   • Reset to auto-detect: defaults delete name.tuley.jay.cd-to cdto-new-window-setting${NC}"
