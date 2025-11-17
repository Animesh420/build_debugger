#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths (script runs from build_debugger directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/sdb"
BUILD_DIR="${PROJECT_DIR}/build"
VCPKG_TOOLCHAIN="${SCRIPT_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake"

# Default options
BUILD_TYPE="Debug"
CLEAN_BUILD=false
RUN_TESTS=false
VERBOSE=false

# Help message
show_help() {
    echo "Usage: ./build.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --clean          Clean build directory before building"
    echo "  -r, --release        Build in Release mode (default: Debug)"
    echo "  -t, --test           Run tests after building"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./build.sh                    # Basic build (Debug)"
    echo "  ./build.sh -c                 # Clean build"
    echo "  ./build.sh -r                 # Release build"
    echo "  ./build.sh -c -r -t           # Clean, Release, and run tests"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -r|--release)
            BUILD_TYPE="Release"
            shift
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Verify paths exist
if [ ! -f "${VCPKG_TOOLCHAIN}" ]; then
    echo -e "${RED}Error: vcpkg toolchain not found at:${NC}"
    echo "  ${VCPKG_TOOLCHAIN}"
    echo ""
    echo "Please ensure vcpkg is properly set up in:"
    echo "  ${SCRIPT_DIR}/vcpkg/"
    exit 1
fi

if [ ! -d "${PROJECT_DIR}" ]; then
    echo -e "${RED}Error: sdb project directory not found at:${NC}"
    echo "  ${PROJECT_DIR}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Building sdb project               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Script directory: ${SCRIPT_DIR}"
echo "  Project directory: ${PROJECT_DIR}"
echo "  Build directory: ${BUILD_DIR}"
echo "  vcpkg toolchain: ${VCPKG_TOOLCHAIN}"
echo "  Build type: ${BUILD_TYPE}"
echo "  Clean build: ${CLEAN_BUILD}"
echo "  Run tests: ${RUN_TESTS}"
echo ""

# Clean build if requested
if [ "${CLEAN_BUILD}" = true ]; then
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    rm -rf "${BUILD_DIR}"
    echo -e "${GREEN}Build directory cleaned!${NC}"
    echo ""
fi

# Create build directory if it doesn't exist
if [ ! -d "${BUILD_DIR}" ]; then
    echo -e "${YELLOW}Creating build directory...${NC}"
    mkdir -p "${BUILD_DIR}"
fi

# Navigate to build directory
cd "${BUILD_DIR}" || exit 1

# Configure with CMake
echo -e "${YELLOW}Configuring with CMake (${BUILD_TYPE})...${NC}"
CMAKE_ARGS=(
    ".."
    "-DCMAKE_TOOLCHAIN_FILE=${VCPKG_TOOLCHAIN}"
    "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
)

if [ "${VERBOSE}" = true ]; then
    CMAKE_ARGS+=("-DCMAKE_VERBOSE_MAKEFILE=ON")
fi

cmake "${CMAKE_ARGS[@]}"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ CMake configuration failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ CMake configuration successful!${NC}"
echo ""

# Build with make
echo -e "${YELLOW}Building with make (using $(nproc) cores)...${NC}"
if [ "${VERBOSE}" = true ]; then
    make VERBOSE=1 -j$(nproc)
else
    make -j$(nproc)
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Build successful!${NC}"
echo ""
echo -e "${BLUE}Build artifacts:${NC}"
if [ -f "${BUILD_DIR}/src/libsdb.a" ]; then
    SIZE=$(du -h "${BUILD_DIR}/src/libsdb.a" | cut -f1)
    echo -e "  ${GREEN}✓${NC} Library: ${BUILD_DIR}/src/libsdb.a (${SIZE})"
else
    echo -e "  ${RED}✗${NC} Library: NOT FOUND"
fi

if [ -f "${BUILD_DIR}/tools/sdb" ]; then
    SIZE=$(du -h "${BUILD_DIR}/tools/sdb" | cut -f1)
    echo -e "  ${GREEN}✓${NC} Executable: ${BUILD_DIR}/tools/sdb (${SIZE})"
else
    echo -e "  ${RED}✗${NC} Executable: NOT FOUND"
fi

if [ -f "${BUILD_DIR}/test/sdb-tests" ]; then
    SIZE=$(du -h "${BUILD_DIR}/test/sdb-tests" | cut -f1)
    echo -e "  ${GREEN}✓${NC} Tests: ${BUILD_DIR}/test/sdb-tests (${SIZE})"
else
    echo -e "  ${RED}✗${NC} Tests: NOT FOUND"
fi

# Run tests if requested
if [ "${RUN_TESTS}" = true ]; then
    echo ""
    echo -e "${YELLOW}Running tests...${NC}"
    ctest --output-on-failure
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
    else
        echo -e "${RED}✗ Some tests failed!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Build completed successfully!      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"