#!/bin/bash

# =============================================================================
# CortexIDE Developer Mode Launcher
# =============================================================================
# This script checks dependencies and launches CortexIDE in Developer Mode.
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
# Step 1: Check and Install Node.js (v22.15.1)
# =============================================================================
check_node() {
    print_info "Checking Node.js version..."

    # Check if fnm is installed
    if ! command -v fnm &> /dev/null; then
        print_error "fnm (Fast Node Manager) not found!"
        print_info "Please install Homebrew and fnm first, or run build_macos.sh"
        exit 1
    fi

    # Source fnm
    export PATH="/Users/$USER/.local/share/fnm:$PATH"
    eval "$(fnm env --shell bash)"

    # Check if Node.js v22.15.1 is installed
    if ! fnm list | grep -q "v22.15.1"; then
        print_warning "Node.js v22.15.1 not found. Installing..."
        fnm install 22.15.1
        fnm use 22.15.1
        fnm default 22.15.1
        print_success "Node.js v22.15.1 installed successfully!"
    fi

    # Use Node.js v22.15.1
    fnm use 22.15.1

    # Verify Node.js version
    NODE_VERSION=$(node --version)
    print_info "Using Node.js version: $NODE_VERSION"
}

# =============================================================================
# Step 2: Check npm dependencies
# =============================================================================
check_dependencies() {
    print_info "Checking npm dependencies..."

    if [ ! -d "node_modules" ]; then
        print_error "node_modules directory not found!"
        print_info "Please run build_macos.sh first to install dependencies."
        exit 1
    fi

    print_success "Dependencies are available."
}

# =============================================================================
# Step 3: Build React components if needed
# =============================================================================
build_react_if_needed() {
    print_info "Checking React components..."

    if [ ! -d "src/vs/workbench/contrib/cortexide/browser/react/out/void-editor-widgets-tsx" ]; then
        print_warning "React components not found. Building..."
        npm run buildreact || {
            print_error "Failed to build React components!"
            exit 1
        }
        print_success "React components built successfully!"
    else
        print_success "React components are up to date."
    fi
}

# =============================================================================
# Step 4: Compile TypeScript if needed
# =============================================================================
compile_ts_if_needed() {
    print_info "Checking TypeScript compilation..."

    # Check if compiled files exist
    if [ ! -d "out" ] || [ ! -f "out/vs/workbench/workbench.desktop.main.js" ]; then
        print_warning "TypeScript not compiled. Compiling..."
        node --max-old-space-size=12288 ./node_modules/gulp/bin/gulp.js compile || {
            print_error "TypeScript compilation failed!"
            exit 1
        }
        print_success "TypeScript compiled successfully!"
    else
        print_success "TypeScript is already compiled."
    fi
}

# =============================================================================
# Step 5: Launch Developer Mode
# =============================================================================
launch_dev_mode() {
    print_info "Launching CortexIDE in Developer Mode..."

    # Change to script directory
    cd "$(dirname "$0")"

    # Run the VSCode development script
    ./scripts/code.sh || {
        print_error "Failed to launch Developer Mode!"
        exit 1
    }
}

# =============================================================================
# Main execution
# =============================================================================
main() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  CortexIDE Developer Mode Launcher${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Store original directory
    ORIGINAL_DIR=$(pwd)

    # Run checks
    check_node
    check_dependencies
    build_react_if_needed
    compile_ts_if_needed

    echo ""
    print_info "Starting CortexIDE Developer Mode..."
    echo ""

    # Change to script directory
    cd "$(dirname "$0")"

    # Launch Developer Mode
    ./scripts/code.sh

    # Return to original directory (this won't be reached if code.sh runs successfully)
    cd "$ORIGINAL_DIR"
}

# Run main function
main "$@"
