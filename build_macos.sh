#!/bin/bash

# =============================================================================
# CortexIDE macOS Build Script
# =============================================================================
# This script checks dependencies, installs them if needed, and builds
# the macOS executable for CortexIDE.
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions for colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Step 1: Check and Install Homebrew
# =============================================================================
check_homebrew() {
    print_info "Checking for Homebrew..."

    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew installed successfully!"
    else
        print_success "Homebrew is already installed."
    fi

    # Ensure Homebrew is in PATH
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# =============================================================================
# Step 2: Check and Install Node.js (v22.15.1)
# =============================================================================
check_node() {
    print_info "Checking for Node.js..."

    # Check if fnm is installed
    if ! command -v fnm &> /dev/null; then
        print_warning "fnm (Fast Node Manager) not found. Installing via Homebrew..."
        brew install fnm
        print_success "fnm installed successfully!"
        # Source fnm
        export PATH="/Users/$USER/.local/share/fnm:$PATH"
        eval "$(fnm env --shell bash)"
    else
        print_success "fnm is already installed."
        export PATH="/Users/$USER/.local/share/fnm:$PATH"
        eval "$(fnm env --shell bash)"
    fi

    # Check if Node.js v22.15.1 is installed
    if ! fnm list | grep -q "v22.15.1"; then
        print_warning "Node.js v22.15.1 not found. Installing..."
        fnm install 22.15.1
        fnm use 22.15.1
        fnm default 22.15.1
        print_success "Node.js v22.15.1 installed successfully!"
    else
        print_success "Node.js v22.15.1 is already installed."
    fi

    # Use Node.js v22.15.1
    fnm use 22.15.1

    # Verify Node.js version
    NODE_VERSION=$(node --version)
    print_info "Using Node.js version: $NODE_VERSION"
}

# =============================================================================
# Step 3: Check and Install npm dependencies
# =============================================================================
check_dependencies() {
    print_info "Checking npm dependencies..."

    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        print_info "node_modules directory exists. Checking if dependencies are up to date..."

        # Install dependencies if needed
        npm install --prefer-offline --no-audit --progress=false || {
            print_warning "npm install failed, retrying..."
            npm install --progress=false
        }
        print_success "Dependencies are up to date."
    else
        print_warning "node_modules directory not found. Installing dependencies..."
        npm install --progress=false
        print_success "Dependencies installed successfully!"
    fi
}

# =============================================================================
# Step 4: Build React components
# =============================================================================
build_react() {
    print_info "Building React components..."

    if command -v npm &> /dev/null; then
        npm run buildreact || {
            print_error "Failed to build React components!"
            exit 1
        }
        print_success "React components built successfully!"
    else
        print_error "npm not found!"
        exit 1
    fi
}

# =============================================================================
# Step 5: Compile TypeScript
# =============================================================================
compile_ts() {
    print_info "Compiling TypeScript..."

    node --max-old-space-size=12288 ./node_modules/gulp/bin/gulp.js compile || {
        print_error "TypeScript compilation failed!"
        exit 1
    }
    print_success "TypeScript compiled successfully!"
}

# =============================================================================
# Step 6: Build macOS executable
# =============================================================================
build_macos() {
    print_info "Building macOS executable..."

    npm run gulp vscode-darwin-x64 || {
        print_error "macOS build failed!"
        exit 1
    }

    # Check multiple possible output locations
    BUILD_DIR=""
    if [ -d "$(pwd)/VSCode-darwin-x64/CortexIDE.app" ]; then
        BUILD_DIR="$(pwd)/VSCode-darwin-x64"
    elif [ -d "$(dirname $(pwd))/VSCode-darwin-x64/CortexIDE.app" ]; then
        BUILD_DIR="$(dirname $(pwd))/VSCode-darwin-x64"
    fi

    if [ -n "$BUILD_DIR" ] && [ -d "$BUILD_DIR/CortexIDE.app" ]; then
        print_success "macOS executable built successfully!"
        print_info "Output location: $BUILD_DIR/CortexIDE.app"
    else
        print_warning "Build completed but couldn't locate CortexIDE.app"
        print_info "Check $(pwd)/VSCode-darwin-x64/ or $(dirname $(pwd))/VSCode-darwin-x64/"
    fi
}

# =============================================================================
# Main execution
# =============================================================================
main() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  CortexIDE macOS Build Script${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Store original directory
    ORIGINAL_DIR=$(pwd)

    # Change to script directory
    cd "$(dirname "$0")"

    # Run checks and builds
    check_homebrew
    check_node
    check_dependencies

    # Only build React if needed (check if React components exist)
    if [ ! -d "src/vs/workbench/contrib/cortexide/browser/react/out" ]; then
        build_react
    else
        print_info "React components already built, skipping..."
    fi

    compile_ts
    build_macos

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Build Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    print_info "You can find the CortexIDE app at:"
    print_info "$(pwd)/VSCode-darwin-x64/CortexIDE.app"
    echo ""

    # Return to original directory
    cd "$ORIGINAL_DIR"
}

# Run main function
main "$@"
