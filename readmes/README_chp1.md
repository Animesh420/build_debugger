# Chapter 1: Project Files and Architecture

Complete guide to understanding every file in the SDB project, their purpose, and how they work together.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Complete File Structure](#complete-file-structure)
3. [Root Directory Files](#root-directory-files)
4. [CMake Files Deep Dive](#cmake-files-deep-dive)
5. [vcpkg Files](#vcpkg-files)
6. [Source Code Files](#source-code-files)
7. [Build Automation Scripts](#build-automation-scripts)
8. [Configuration Files](#configuration-files)
9. [How Files Work Together](#how-files-work-together)

---

## Project Overview

**SDB (Simple Debugger)** is a C++ project demonstrating:
- Modern CMake multi-directory build system
- Dependency management with vcpkg
- Library and executable separation
- Automated testing with Catch2

---

## Complete File Structure

```
build_debugger/                         # Workspace root
│
├── .gitignore                          # Git ignore rules
├── .vscode/                            # VSCode configuration
│   └── tasks.json                      # Build tasks
│
├── README.md                           # Main project documentation
├── readmes/                            # Detailed documentation
│   └── README_chp1.md                  # This file
│
├── build.sh                            # Main build script
├── clean.sh                            # Clean build artifacts
├── run.sh                              # Run the debugger
├── test.sh                             # Run tests
│
├── vcpkg/                              # Package manager directory
│   ├── .git/                           # vcpkg git repository
│   ├── bootstrap-vcpkg.sh              # Initial setup script
│   ├── vcpkg                           # vcpkg executable (after bootstrap)
│   ├── .vcpkg-root                     # Marks vcpkg root
│   ├── ports/                          # Package definitions
│   │   ├── catch2/                     # Catch2 build recipe
│   │   └── [1000+ packages]/
│   ├── scripts/
│   │   └── buildsystems/
│   │       └── vcpkg.cmake             # CMake integration file
│   ├── buildtrees/                     # Temporary build files (ignored)
│   ├── downloads/                      # Downloaded archives (ignored)
│   ├── installed/                      # Installed packages (ignored)
│   └── packages/                       # Package staging (ignored)
│
├── git_clone_sdb/                      # Original cloned project (ignored)
│
└── sdb/                                # Main project directory
    ├── CMakeLists.txt                  # Root CMake configuration
    ├── vcpkg.json                      # Dependency manifest
    ├── CMakePresets.json               # CMake build presets
    ├── LICENSE.txt                     # Project license
    │
    ├── include/                        # Public API headers
    │   └── libsdb/
    │       └── libsdb.hpp              # Library public interface
    │
    ├── src/                            # Library implementation
    │   ├── CMakeLists.txt              # Library build configuration
    │   └── libsdb.cpp                  # Library source code
    │
    ├── tools/                          # Executable programs
    │   ├── CMakeLists.txt              # Tools build configuration
    │   └── sdb.cpp                     # Main debugger program
    │
    ├── test/                           # Unit tests
    │   ├── CMakeLists.txt              # Test build configuration
    │   └── tests.cpp                   # Test cases
    │
    └── build/                          # Build output directory (ignored)
        ├── CMakeCache.txt              # CMake configuration cache
        ├── Makefile                    # Generated build file
        ├── vcpkg_installed/            # Project dependencies
        │   └── x64-linux/
        │       ├── include/            # Dependency headers
        │       ├── lib/                # Dependency libraries
        │       └── share/              # CMake configs
        ├── src/
        │   └── libsdb.a                # Built static library
        ├── tools/
        │   └── sdb                     # Built executable
        └── test/
            └── sdb-tests               # Built test executable
```

---

## Root Directory Files

### `.gitignore`

**Purpose:** Tells Git which files to ignore (not track in version control)

**Location:** `build_debugger/.gitignore`

**Content Explanation:**

```gitignore
# Ignore cloned repository directory
git_clone_sdb/

# Ignore build output directories
sdb/build/
build/
out/

# Ignore vcpkg build artifacts (downloaded and built packages)
vcpkg/buildtrees/      # Temporary build files
vcpkg/downloads/       # Downloaded source archives
vcpkg/installed/       # Installed packages
vcpkg/packages/        # Package staging area

# Ignore compiled object files
*.o                    # GCC object files
*.a                    # Static libraries
*.so                   # Shared libraries

# Ignore editor files
.vscode/               # VSCode settings
*.swp                  # Vim swap files
.DS_Store              # macOS system files
```

**Why these are ignored:**
- **Build artifacts**: Can be regenerated, large files
- **vcpkg cache**: Downloaded/built packages, shared across projects
- **Editor files**: User-specific preferences
- **Temporary files**: Not part of source code

**What IS tracked:**
- Source code (`.cpp`, `.hpp`)
- CMake files (`CMakeLists.txt`)
- Build scripts (`.sh`)
- Documentation (`.md`)
- Configuration (`vcpkg.json`, `CMakePresets.json`)

---

### `.vscode/tasks.json`

**Purpose:** Defines VSCode build tasks for quick access

**Location:** `build_debugger/.vscode/tasks.json`

**Structure:**

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "CMake Configure + Build (sdb)",
            "dependsOn": [
                "CMake Configure (sdb)",
                "Make Build (sdb)"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

**What it provides:**
- Press `Ctrl+Shift+B` to build
- Tasks menu access (`Ctrl+Shift+P` → "Tasks: Run Task")
- Pre-configured commands with correct paths

**Task Types:**
1. **CMake Configure**: Run CMake with toolchain file
2. **Make Build**: Compile the code
3. **Combined**: Configure + Build in sequence
4. **Clean**: Remove build artifacts
5. **Run Tests**: Execute test suite

---

### `README.md`

**Purpose:** Main project documentation entry point

**Location:** `build_debugger/README.md`

**Contains:**
- Project overview
- Quick start guide
- Build instructions
- Links to detailed documentation
- Troubleshooting tips

**Audience:** New users, contributors, anyone discovering the project

---

## CMake Files Deep Dive

CMake uses multiple `CMakeLists.txt` files in a **hierarchical structure**. Each file has a specific responsibility.

### Why Multiple CMakeLists.txt Files?

```
Root CMakeLists.txt
    ├── Coordinates the entire project
    ├── Sets global settings
    └── Delegates to subdirectories
         ↓
Subdirectory CMakeLists.txt
    ├── Builds specific component
    ├── Defines targets (libraries/executables)
    └── Manages component-specific settings
```

**Benefits:**
1. **Modularity**: Each component is self-contained
2. **Maintainability**: Easy to modify one part without breaking others
3. **Reusability**: Components can be used independently
4. **Clarity**: Clear separation of concerns

---

### [1] Root CMakeLists.txt

**Location:** `sdb/CMakeLists.txt`

**Complete File:**

```cmake
cmake_minimum_required(VERSION 3.14)
project(sdb VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find libedit from system using pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(libedit REQUIRED IMPORTED_TARGET libedit)

option(BUILD_TESTING "Build tests" ON)
if(BUILD_TESTING)
    enable_testing()
endif()

add_subdirectory(src)
add_subdirectory(tools)

if(BUILD_TESTING)
    add_subdirectory(test)
endif()
```

**Line-by-Line Explanation:**

#### 1. Minimum CMake Version

```cmake
cmake_minimum_required(VERSION 3.14)
```

- **What:** Requires CMake 3.14 or newer
- **Why:** Project uses features introduced in CMake 3.14+
- **If missing:** CMake will error out if version is too old

#### 2. Project Declaration

```cmake
project(sdb VERSION 1.0 LANGUAGES CXX)
```

- **What:** Declares a project named "sdb"
- **VERSION 1.0:** Sets project version to 1.0
- **LANGUAGES CXX:** Only uses C++ (not C or other languages)
- **Effect:** Sets variables like `PROJECT_NAME`, `PROJECT_VERSION`

#### 3. C++ Standard

```cmake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

- **First line:** Use C++17 features
- **Second line:** Make it mandatory (don't fall back to older standards)
- **Result:** All targets will be compiled with `-std=c++17` flag
- **Why C++17:** Modern features like `std::filesystem`, structured bindings

#### 4. Find System Library (libedit)

```cmake
find_package(PkgConfig REQUIRED)
pkg_check_modules(libedit REQUIRED IMPORTED_TARGET libedit)
```

**What is pkg-config?**
- Tool to query system-installed libraries
- Returns compiler/linker flags needed to use a library
- Alternative to CMake's `find_package()`

**First line:**
```cmake
find_package(PkgConfig REQUIRED)
```
- Finds the `pkg-config` tool itself
- **REQUIRED:** Stop if not found
- Sets `PKG_CONFIG_FOUND` variable

**Second line:**
```cmake
pkg_check_modules(libedit REQUIRED IMPORTED_TARGET libedit)
```
- **pkg_check_modules:** Function from PkgConfig module
- **libedit:** Variable prefix (creates `libedit_FOUND`, `libedit_LIBRARIES`, etc.)
- **REQUIRED:** Stop if library not found
- **IMPORTED_TARGET:** Creates `PkgConfig::libedit` target for easy linking
- **libedit (argument):** Library name to search for (looks for `libedit.pc` file)

**What happens:**
```bash
# CMake runs behind the scenes:
pkg-config --cflags libedit    # Get compiler flags
pkg-config --libs libedit      # Get linker flags

# Output example:
-I/usr/include              # Include path
-ledit -lncurses            # Libraries to link
```

**Result:** Creates CMake target `PkgConfig::libedit` that can be linked against

#### 5. Testing Configuration

```cmake
option(BUILD_TESTING "Build tests" ON)
if(BUILD_TESTING)
    enable_testing()
endif()
```

**First line:**
```cmake
option(BUILD_TESTING "Build tests" ON)
```
- **option():** Creates a user-configurable boolean variable
- **BUILD_TESTING:** Variable name
- **"Build tests":** Description shown in cmake-gui
- **ON:** Default value (enabled)
- **Can override:** `cmake .. -DBUILD_TESTING=OFF`

**Second line:**
```cmake
if(BUILD_TESTING)
    enable_testing()
endif()
```
- **enable_testing():** Activates CTest integration
- **Effect:** Allows running `ctest` command
- Only enabled if `BUILD_TESTING=ON`

#### 6. Add Subdirectories

```cmake
add_subdirectory(src)
add_subdirectory(tools)

if(BUILD_TESTING)
    add_subdirectory(test)
endif()
```

**What `add_subdirectory()` does:**
1. Processes `CMakeLists.txt` in that directory
2. Variables/targets defined there become available
3. Creates a sub-scope (variables can be local)

**Execution order:**
```
1. Process src/CMakeLists.txt
   └─→ Defines libsdb library target

2. Process tools/CMakeLists.txt
   └─→ Defines sdb executable target
   └─→ Can use libsdb target from step 1

3. Process test/CMakeLists.txt (if testing enabled)
   └─→ Defines sdb-tests target
   └─→ Can use libsdb target from step 1
```

**Why conditional test/?**
- Testing is optional
- Faster builds when tests not needed
- Useful for production builds

---

### [2] Library CMakeLists.txt

**Location:** `sdb/src/CMakeLists.txt`

**Complete File:**

```cmake
add_library(libsdb libsdb.cpp)
add_library(sdb::libsdb ALIAS libsdb)

set_target_properties(libsdb PROPERTIES OUTPUT_NAME sdb)
target_compile_features(libsdb PUBLIC cxx_std_17)

target_include_directories(libsdb
    PUBLIC
      $<INSTALL_INTERFACE:include>
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/include
)

include(GNUInstallDirs)
install(TARGETS libsdb
    EXPORT sdb-targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(EXPORT sdb-targets
    FILE sdb-config.cmake
    NAMESPACE sdb::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/sdb
)
```

**Line-by-Line Explanation:**

#### 1. Create Library

```cmake
add_library(libsdb libsdb.cpp)
```

- **add_library:** Creates a library target
- **libsdb:** Target name (used in CMake commands)
- **libsdb.cpp:** Source file(s) to compile
- **Default type:** Static library (`.a` on Linux)
- **Output:** `build/src/libsdb.a`

**What happens during build:**
```bash
# Compile source to object file
g++ -c libsdb.cpp -o libsdb.cpp.o -std=c++17 -I../../include

# Archive object files into library
ar rcs libsdb.a libsdb.cpp.o
```

#### 2. Create Alias

```cmake
add_library(sdb::libsdb ALIAS libsdb)
```

- **ALIAS:** Creates an alternative name
- **sdb::libsdb:** Namespaced name (convention: `namespace::target`)
- **Why:** Consistent with installed package naming
- **Usage:** Other targets use `target_link_libraries(mytarget sdb::libsdb)`

**Benefits:**
- Clear indication this is an external dependency
- Matches naming convention of installed packages
- Prevents naming conflicts

#### 3. Set Library Properties

```cmake
set_target_properties(libsdb PROPERTIES OUTPUT_NAME sdb)
```

- **set_target_properties:** Modifies target settings
- **libsdb:** Target to modify
- **OUTPUT_NAME sdb:** Final library name will be `libsdb.a` (not `liblibsdb.a`)
- **Why:** Unix convention is `lib<name>.a`, so `sdb` → `libsdb.a`

#### 4. Require C++17

```cmake
target_compile_features(libsdb PUBLIC cxx_std_17)
```

- **target_compile_features:** Sets required C++ features
- **libsdb:** Target to apply to
- **PUBLIC:** This target AND anything linking to it requires C++17
- **cxx_std_17:** C++17 standard
- **Effect:** Adds `-std=c++17` compiler flag

**PUBLIC vs PRIVATE:**
- **PUBLIC:** Requirement propagates (linked targets also need C++17)
- **PRIVATE:** Only this target needs C++17

#### 5. Include Directories

```cmake
target_include_directories(libsdb
    PUBLIC
      $<INSTALL_INTERFACE:include>
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/include
)
```

**What are include directories?**
- Paths where compiler searches for `#include` files
- Added as `-I/path/to/include` flags

**PUBLIC includes:**
```cmake
PUBLIC
  $<INSTALL_INTERFACE:include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
```

- **PUBLIC:** Available to this target AND anyone linking to it
- **$<BUILD_INTERFACE:...>:** Only used during build
  - `${CMAKE_SOURCE_DIR}/include` = `build_debugger/sdb/include`
  - Contains `libsdb/libsdb.hpp`
- **$<INSTALL_INTERFACE:...>:** Only used after installation
  - After `make install`, headers will be in system directories
  - `include` is relative to install prefix

**PRIVATE includes:**
```cmake
PRIVATE
    ${CMAKE_SOURCE_DIR}/src/include
```

- **PRIVATE:** Only for building this library
- Internal implementation headers
- NOT available to users of the library

**Example:**

```cpp
// In libsdb.cpp:
#include <libsdb/libsdb.hpp>     // Found via PUBLIC include
#include "internal/details.hpp"  // Found via PRIVATE include

// In tools/sdb.cpp (links to libsdb):
#include <libsdb/libsdb.hpp>     // Found via PUBLIC include (inherited)
#include "internal/details.hpp"  // ERROR! Not available (was PRIVATE)
```

#### 6. Installation Rules

```cmake
include(GNUInstallDirs)
```

- **include:** Loads CMake module
- **GNUInstallDirs:** Defines standard installation directories
- **Sets variables:**
  - `CMAKE_INSTALL_BINDIR` = `bin` (executables)
  - `CMAKE_INSTALL_LIBDIR` = `lib` or `lib64` (libraries)
  - `CMAKE_INSTALL_INCLUDEDIR` = `include` (headers)

**Install library:**

```cmake
install(TARGETS libsdb
    EXPORT sdb-targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
```

- **install(TARGETS ...):** Install built target
- **EXPORT sdb-targets:** Create export set (for `find_package()`)
- **ARCHIVE:** Where to install static libraries (`.a`)
- **LIBRARY:** Where to install shared libraries (`.so`)
- **RUNTIME:** Where to install executables (DLLs on Windows)
- **INCLUDES:** Where headers are installed (used by export)

**Example result:**
```
/usr/local/lib/libsdb.a                    # Library
/usr/local/include/libsdb/libsdb.hpp       # Header
/usr/local/lib/cmake/sdb/sdb-config.cmake  # CMake config
```

**Install headers:**

```cmake
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
```

- **install(DIRECTORY ...):** Copy entire directory
- **${PROJECT_SOURCE_DIR}/include/:** Source directory (trailing `/` means contents)
- **DESTINATION:** Where to copy to

**Install CMake config:**

```cmake
install(EXPORT sdb-targets
    FILE sdb-config.cmake
    NAMESPACE sdb::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/sdb
)
```

- **install(EXPORT ...):** Generate CMake config file
- **sdb-targets:** Export set defined earlier
- **FILE:** Config filename
- **NAMESPACE:** Prefix for targets (`sdb::libsdb`)
- **Result:** Creates `sdb-config.cmake` that other projects can use

**How it's used:**

```cmake
# In another project:
find_package(sdb REQUIRED)
target_link_libraries(myapp sdb::libsdb)
```

---

### [3] Tools CMakeLists.txt

**Location:** `sdb/tools/CMakeLists.txt`

**Complete File:**

```cmake
add_executable(sdb sdb.cpp)

target_link_libraries(sdb PRIVATE 
    sdb::libsdb 
    PkgConfig::libedit
)

include(GNUInstallDirs)
install(
    TARGETS sdb 
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
```

**Line-by-Line Explanation:**

#### 1. Create Executable

```cmake
add_executable(sdb sdb.cpp)
```

- **add_executable:** Creates executable target
- **sdb:** Target name AND output filename
- **sdb.cpp:** Source file with `main()` function
- **Output:** `build/tools/sdb` (executable)

**What happens during build:**
```bash
# Compile source
g++ -c sdb.cpp -o sdb.cpp.o -std=c++17 -I../../include

# Link executable (happens in next step)
```

#### 2. Link Libraries

```cmake
target_link_libraries(sdb PRIVATE 
    sdb::libsdb 
    PkgConfig::libedit
)
```

- **target_link_libraries:** Specify dependencies
- **sdb:** Target that needs dependencies
- **PRIVATE:** Dependencies not propagated (sdb is final executable)
- **sdb::libsdb:** Our library (defined in `src/CMakeLists.txt`)
- **PkgConfig::libedit:** System library (found in root CMakeLists.txt)

**What happens:**

1. **Inherits properties from sdb::libsdb:**
   - Include directories (`build_debugger/sdb/include`)
   - Compile features (C++17)
   
2. **Links against libraries:**
   ```bash
   g++ sdb.cpp.o -o sdb \
       ../../src/libsdb.a \        # Our library
       -ledit \                     # libedit
       -lncurses                    # libedit dependency
   ```

**Dependency chain:**
```
sdb.cpp.o
    ↓ (links)
sdb::libsdb (libsdb.a)
    ↓ (compiled into)
libsdb.cpp.o
```

#### 3. Install Executable

```cmake
include(GNUInstallDirs)
install(
    TARGETS sdb 
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
```

- **install(TARGETS sdb ...):** Install the executable
- **RUNTIME:** Specifies it's an executable
- **DESTINATION:** Install to `bin/` directory
- **Result:** `/usr/local/bin/sdb` (or similar)

**After installation:**
```bash
# Can run from anywhere:
sdb --help
```

---

### [4] Test CMakeLists.txt

**Location:** `sdb/test/CMakeLists.txt`

**Complete File:**

```cmake
find_package(Catch2 CONFIG REQUIRED)

add_executable(sdb-tests tests.cpp)

target_link_libraries(sdb-tests PRIVATE 
    sdb::libsdb
    Catch2::Catch2WithMain
)

include(CTest)
include(Catch)
catch_discover_tests(sdb-tests)
```

**Line-by-Line Explanation:**

#### 1. Find Test Framework

```cmake
find_package(Catch2 CONFIG REQUIRED)
```

- **find_package:** Search for installed package
- **Catch2:** Package name
- **CONFIG:** Use package's CMake config file (not FindModule)
- **REQUIRED:** Stop if not found

**Where it searches:**
1. `build/vcpkg_installed/x64-linux/share/catch2/` (vcpkg-installed)
2. System paths (`/usr/local/lib/cmake/catch2/`)

**What it finds:**
- `Catch2Config.cmake` - Package configuration
- Creates targets: `Catch2::Catch2`, `Catch2::Catch2WithMain`

**CONFIG vs MODULE:**
- **CONFIG mode:** Uses package-provided config (`Catch2Config.cmake`)
- **MODULE mode:** Uses CMake's find script (`FindCatch2.cmake`)
- **vcpkg packages:** Always use CONFIG mode

#### 2. Create Test Executable

```cmake
add_executable(sdb-tests tests.cpp)
```

- **add_executable:** Creates test executable
- **sdb-tests:** Target name
- **tests.cpp:** Test source file
- **Output:** `build/test/sdb-tests`

#### 3. Link Test Dependencies

```cmake
target_link_libraries(sdb-tests PRIVATE 
    sdb::libsdb
    Catch2::Catch2WithMain
)
```

- **sdb::libsdb:** Library to test
- **Catch2::Catch2WithMain:** Test framework with `main()` function
- **PRIVATE:** Test dependencies don't propagate

**Catch2::Catch2WithMain provides:**
- Test runner (no need to write `main()`)
- Test discovery
- Command-line argument parsing

**What gets linked:**
```bash
g++ tests.cpp.o -o sdb-tests \
    ../../src/libsdb.a \                              # Our library
    ../vcpkg_installed/x64-linux/lib/libCatch2Main.a \  # Catch2 main
    ../vcpkg_installed/x64-linux/lib/libCatch2.a        # Catch2 core
```

#### 4. Enable Testing

```cmake
include(CTest)
```

- **include(CTest):** Load CTest module
- **Effect:** Enables `ctest` command
- **Creates:** `CTestTestfile.cmake` in build directory

#### 5. Catch2 Integration

```cmake
include(Catch)
catch_discover_tests(sdb-tests)
```

- **include(Catch):** Load Catch2 CMake module
- **catch_discover_tests(...):** Auto-discover test cases

**What `catch_discover_tests()` does:**

1. **After build**, CMake runs:
   ```bash
   ./sdb-tests --list-tests --list-test-names-only
   ```

2. **Parses output** to find all `TEST_CASE()` macros

3. **Registers** each test case with CTest

4. **Result:** Each test can be run individually:
   ```bash
   ctest -R "test_name"           # Run specific test
   ctest                          # Run all tests
   ctest --output-on-failure      # Show output only for failures
   ```

**Example test discovery:**

```cpp
// In tests.cpp:
TEST_CASE("validate environment") { ... }
TEST_CASE("another test") { ... }
```

**CTest sees:**
```
Test project /path/to/build
    Start 1: validate environment
    Start 2: another test
```

---

## vcpkg Files

### vcpkg Directory Structure

```
vcpkg/
├── .vcpkg-root                   # Marker file (identifies vcpkg root)
├── bootstrap-vcpkg.sh            # First-time setup script
├── vcpkg                         # Main vcpkg executable (after bootstrap)
│
├── ports/                        # Package build recipes
│   └── catch2/
│       ├── portfile.cmake        # Build instructions
│       ├── vcpkg.json            # Package metadata
│       └── usage                 # Usage instructions
│
└── scripts/
    └── buildsystems/
        └── vcpkg.cmake           # CMake integration (THE IMPORTANT ONE)
```

---

### vcpkg.cmake - Toolchain File

**Location:** `vcpkg/scripts/buildsystems/vcpkg.cmake`

**Purpose:** Integrates vcpkg with CMake

**This is THE key file** that makes vcpkg work with CMake!

**What it does:**

1. **Executed BEFORE `project()` command**
   - Runs as part of CMake initialization
   - Sets up environment before project configuration

2. **Reads vcpkg.json manifest**
   - Finds project dependencies
   - Determines what needs to be installed

3. **Installs missing packages**
   - Downloads source code
   - Builds packages
   - Installs to `vcpkg_installed/` directory

4. **Configures package search paths**
   - Modifies `CMAKE_PREFIX_PATH`
   - Ensures `find_package()` finds vcpkg packages first

5. **Sets up triplet (platform)**
   - Detects: `x64-linux`, `x64-windows`, `arm64-osx`, etc.
   - Determines: Static/dynamic linking, debug/release

**Simplified version of what's inside:**

```cmake
# vcpkg.cmake (conceptual, not actual code)

# 1. Determine vcpkg root
set(VCPKG_ROOT "${CMAKE_CURRENT_LIST_DIR}/../..")

# 2. Detect platform triplet
if(UNIX AND NOT APPLE)
    set(VCPKG_TARGET_TRIPLET "x64-linux")
endif()

# 3. Read vcpkg.json and install packages
if(EXISTS "${CMAKE_SOURCE_DIR}/vcpkg.json")
    execute_process(
        COMMAND ${VCPKG_ROOT}/vcpkg install --triplet ${VCPKG_TARGET_TRIPLET}
    )
endif()

# 4. Add vcpkg installed packages to search path
list(APPEND CMAKE_PREFIX_PATH 
    "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}"
)

# 5. Modify find_package() to search vcpkg first
# (complex macro overrides, simplified here)
```

**How to use:**

```bash
cmake .. -DCMAKE_TOOLCHAIN_FILE=../../vcpkg/scripts/buildsystems/vcpkg.cmake
```

- **-DCMAKE_TOOLCHAIN_FILE:** CMake option for toolchain
- **Must be set on FIRST configuration**
- Cannot be changed after initial configuration
- Stored in `CMakeCache.txt`

---

### vcpkg.json - Manifest File

**Location:** `sdb/vcpkg.json`

**Complete File:**

```json
{
  "name": "sdb",
  "version": "0.1.0",
  "dependencies": [
    "catch2"
  ]
}
```

**Field Explanations:**

#### name

```json
"name": "sdb"
```

- **Required:** Yes
- **Must match:** CMake `project()` name (lowercased)
- **Used for:** vcpkg identification
- **Rules:** Lowercase, alphanumeric, hyphens only

#### version

```json
"version": "0.1.0"
```

- **Required:** Yes
- **Format:** Semantic versioning (`major.minor.patch`)
- **Purpose:** Track project version

#### dependencies

```json
"dependencies": [
  "catch2"
]
```

- **Required:** No (can be empty array)
- **Format:** Array of package names or objects
- **Simple form:** Just package name (latest version)
- **Complex form:** Object with version constraints

**Dependency formats:**

```json
"dependencies": [
    "catch2",                           // Latest version
    
    {
        "name": "fmt",
        "version>=": "9.0.0"            // Minimum version
    },
    
    {
        "name": "spdlog",
        "version>=": "1.10.0",
        "features": ["fmt-external"]    // Enable features
    }
]
```

**Available fields:**

```json
{
  "name": "sdb",                        // Project name
  "version": "0.1.0",                   // Project version
  "description": "Simple Debugger",     // Optional description
  "license": "MIT",                     // Optional license
  
  "dependencies": [                     // Runtime dependencies
    "catch2"
  ],
  
  "dev-dependencies": [                 // Development-only
    "benchmark"
  ],
  
  "features": {                         // Optional features
    "tests": {
      "description": "Build tests",
      "dependencies": ["catch2"]
    }
  },
  
  "builtin-baseline": "commit-hash"    // vcpkg version
}
```

**What happens during build:**

```
1. CMake loads vcpkg.cmake toolchain
   ↓
2. vcpkg.cmake reads vcpkg.json
   ↓
3. Checks each dependency:
   - Is catch2 installed in vcpkg_installed/?
   - No → Download and build it
   ↓
4. Installs to: build/vcpkg_installed/x64-linux/
   ↓
5. CMake continues with find_package(Catch2)
   - Now succeeds because vcpkg installed it
```

---

### CMakePresets.json

**Location:** `sdb/CMakePresets.json`

**Purpose:** Predefined CMake configurations

**Complete File:**

```json
{
    "version": 3,
    "configurePresets": [
        {
            "name": "vcpkg",
            "generator": "Unix Makefiles",
            "cacheVariables": {
                "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/../vcpkg/scripts/buildsystems/vcpkg.cmake"
            }
        }
    ]
}
```

**Field Explanations:**

#### version

```json
"version": 3
```

- **Format version:** CMakePresets.json schema version
- **Version 3:** CMake 3.21+
- **Purpose:** Defines available features

#### configurePresets

```json
"configurePresets": [...]
```

- **Array of presets:** Different build configurations
- **Each preset:** Named configuration with settings

#### Preset Fields

```json
{
    "name": "vcpkg",                    // Preset identifier
    "generator": "Unix Makefiles",      // Build system to use
    "cacheVariables": {                 // CMake cache variables
        "CMAKE_TOOLCHAIN_FILE": "..."   // vcpkg integration
    }
}
```

**How to use:**

```bash
# Without presets:
cmake .. -DCMAKE_TOOLCHAIN_FILE=../../vcpkg/scripts/buildsystems/vcpkg.cmake

# With presets:
cmake --preset=vcpkg
```

**Benefits:**
- Shorter commands
- Consistent configuration
- Shareable across team
- Version controlled

**Extended example:**

```json
{
    "version": 3,
    "configurePresets": [
        {
            "name": "vcpkg-debug",
            "generator": "Unix Makefiles",
            "binaryDir": "${sourceDir}/build/debug",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Debug",
                "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/../vcpkg/scripts/buildsystems/vcpkg.cmake"
            }
        },
        {
            "name": "vcpkg-release",
            "generator": "Unix Makefiles",
            "binaryDir": "${sourceDir}/build/release",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Release",
                "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/../vcpkg/scripts/buildsystems/vcpkg.cmake"
            }
        }
    ]
}
```

---

## Source Code Files

### include/libsdb/libsdb.hpp

**Location:** `sdb/include/libsdb/libsdb.hpp`

**Purpose:** Public API header for the library

**Typical contents:**

```cpp
#pragma once

namespace sdb {
    class debugger {
    public:
        void run();
        // Public interface
    };
}
```

**Why in include/ directory:**
- Public interface (users of the library see this)
- Separate from implementation
- Installed to system directories (`/usr/local/include/`)

**Header guard:**
```cpp
#pragma once    // Modern approach (compiler-specific)
// OR
#ifndef LIBSDB_HPP
#define LIBSDB_HPP
// ... declarations ...
#endif
```

---

### src/libsdb.cpp

**Location:** `sdb/src/libsdb.cpp`

**Purpose:** Library implementation

**Typical contents:**

```cpp
#include <libsdb/libsdb.hpp>

namespace sdb {
    void debugger::run() {
        // Implementation
    }
}
```

**Why separate from header:**
- Hides implementation details
- Faster compilation (changes don't affect all users)
- Reduces binary size

---

### tools/sdb.cpp

**Location:** `sdb/tools/sdb.cpp`

**Purpose:** Main executable program

**Typical contents:**

```cpp
#include <libsdb/libsdb.hpp>

int main(int argc, char** argv) {
    sdb::debugger dbg;
    dbg.run();
    return 0;
}
```

**Why separate tool:**
- Library can be used by multiple programs
- Library can be tested independently
- Clear separation: library logic vs user interface

---

### test/tests.cpp

**Location:** `sdb/test/tests.cpp`

**Purpose:** Unit tests for the library

**Typical contents:**

```cpp
#include <catch2/catch_test_macros.hpp>
#include <libsdb/libsdb.hpp>

TEST_CASE("validate environment") {
    // Test code
    REQUIRE(true);
}
```

**Test structure:**
- **TEST_CASE:** Defines a test
- **REQUIRE:** Assertion (fails test if false)
- **SECTION:** Sub-test within a test case

**Why Catch2:**
- Header-only (easy to integrate)
- Modern C++ syntax
- Automatic test discovery
- Descriptive output

---

## Build Automation Scripts

### build.sh

**Location:** `build_debugger/build.sh`

**Purpose:** Automate the build process

**Key sections:**

```bash
#!/bin/bash

# 1. Path setup (relative paths)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/sdb"
BUILD_DIR="${PROJECT_DIR}/build"
VCPKG_TOOLCHAIN="${SCRIPT_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake"

# 2. Parse options (-c, -r, -t, -v)
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean) CLEAN_BUILD=true ;;
        -r|--release) BUILD_TYPE="Release" ;;
        # ... more options
    esac
done

# 3. Clean (if requested)
if [ "${CLEAN_BUILD}" = true ]; then
    rm -rf "${BUILD_DIR}"
fi

# 4. Create build directory
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 5. Configure with CMake
cmake .. -DCMAKE_TOOLCHAIN_FILE="${VCPKG_TOOLCHAIN}" \
         -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"

# 6. Build with make
make -j$(nproc)

# 7. Run tests (if requested)
if [ "${RUN_TESTS}" = true ]; then
    ctest --output-on-failure
fi
```

**Options:**
- `-c, --clean`: Clean before build
- `-r, --release`: Release mode (optimizations)
- `-t, --test`: Run tests after build
- `-v, --verbose`: Verbose output

**Usage:**
```bash
./build.sh              # Debug build
./build.sh -c           # Clean + debug
./build.sh -r           # Release build
./build.sh -c -r -t     # Clean + release + test
```

---

### clean.sh

**Location:** `build_debugger/clean.sh`

**Purpose:** Remove build artifacts

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/sdb/build"

echo "Cleaning ${BUILD_DIR}..."
rm -rf "${BUILD_DIR}"
echo "Done!"
```

**What it removes:**
- All compiled files
- CMake cache
- vcpkg installed packages (in build/)
- Test executables

**When to use:**
- Build corruption
- CMake configuration issues
- Starting fresh

---

### run.sh

**Location:** `build_debugger/run.sh`

**Purpose:** Run the built executable

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXECUTABLE="${SCRIPT_DIR}/sdb/build/tools/sdb"

if [ ! -f "${EXECUTABLE}" ]; then
    echo "Error: Executable not found"
    echo "Run ./build.sh first"
    exit 1
fi

"${EXECUTABLE}" "$@"
```

**Features:**
- Checks if executable exists
- Forwards arguments to program
- Provides helpful error messages

**Usage:**
```bash
./run.sh                # Run with no args
./run.sh --help         # Pass --help to program
./run.sh arg1 arg2      # Pass multiple args
```

---

### test.sh

**Location:** `build_debugger/test.sh`

**Purpose:** Run unit tests

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/sdb/build"

cd "${BUILD_DIR}"
ctest --output-on-failure "$@"
```

**Features:**
- Changes to build directory
- Runs CTest
- Shows output for failures
- Forwards arguments to ctest

**Usage:**
```bash
./test.sh                    # Run all tests
./test.sh -R "test_name"     # Run specific test
./test.sh -V                 # Verbose output
./test.sh --rerun-failed     # Run only failed tests
```

---

## Configuration Files

### LICENSE.txt

**Location:** `sdb/LICENSE.txt`

**Purpose:** Legal license for the code

**Common licenses:**
- MIT: Permissive, simple
- Apache 2.0: Permissive, patent grant
- GPL: Copyleft, requires derivatives to be open source

**Why important:**
- Defines usage rights
- Protects contributors
- Required for open source

---

## How Files Work Together

### Build Flow

```
User runs: ./build.sh
    ↓
1. build.sh sets up paths
   - SCRIPT_DIR = build_debugger/
   - VCPKG_TOOLCHAIN = vcpkg/scripts/buildsystems/vcpkg.cmake
    ↓
2. Creates and enters build directory
   - mkdir -p sdb/build
   - cd sdb/build
    ↓
3. Runs CMake with toolchain file
   cmake .. -DCMAKE_TOOLCHAIN_FILE=${VCPKG_TOOLCHAIN}
    ↓
4. CMake loads vcpkg.cmake (BEFORE project())
   - Reads sdb/vcpkg.json
   - Sees dependency: "catch2"
   - Installs to: build/vcpkg_installed/
    ↓
5. CMake processes sdb/CMakeLists.txt
   - Sets C++17 standard
   - Finds libedit via pkg-config
   - Processes subdirectories:
     ├── src/CMakeLists.txt → Creates libsdb.a
     ├── tools/CMakeLists.txt → Creates sdb executable
     └── test/CMakeLists.txt → Creates sdb-tests
    ↓
6. CMake generates Makefiles
    ↓
7. make compiles everything
   - src/libsdb.cpp → src/libsdb.a
   - tools/sdb.cpp → tools/sdb (links libsdb.a + libedit)
   - test/tests.cpp → test/sdb-tests (links libsdb.a + Catch2)
    ↓
8. If -t flag: ctest runs tests
    ↓
9. Build complete!
```

### File Dependencies

```
build.sh
    ↓ sets path to ↓
vcpkg/scripts/buildsystems/vcpkg.cmake
    ↓ reads ↓
sdb/vcpkg.json
    ↓ lists dependency: "catch2" ↓
vcpkg/ports/catch2/
    ↓ installs to ↓
sdb/build/vcpkg_installed/x64-linux/
    ↓ used by ↓
sdb/test/CMakeLists.txt (find_package(Catch2))
    ↓ links ↓
sdb/test/sdb-tests (executable)
```

### CMake Hierarchy

```
sdb/CMakeLists.txt (ROOT)
    ├── Sets: C++17, project version
    ├── Finds: libedit (system)
    └── Delegates to:
         ├── src/CMakeLists.txt
         │   └── Creates: libsdb.a
         │       └── Exports: sdb::libsdb target
         │
         ├── tools/CMakeLists.txt
         │   └── Creates: sdb executable
         │       └── Links: sdb::libsdb + PkgConfig::libedit
         │
         └── test/CMakeLists.txt
             └── Finds: Catch2 (vcpkg)
             └── Creates: sdb-tests executable
                 └── Links: sdb::libsdb + Catch2::Catch2WithMain
```

---

## Summary

### Critical Files

| File | Purpose | Cannot build without |
|------|---------|---------------------|
| `vcpkg/scripts/buildsystems/vcpkg.cmake` | CMake-vcpkg integration | ✅ Yes |
| `sdb/vcpkg.json` | Dependency list | ✅ Yes |
| `sdb/CMakeLists.txt` | Root build config | ✅ Yes |
| `src/CMakeLists.txt` | Library build | ✅ Yes |
| `tools/CMakeLists.txt` | Executable build | ✅ Yes |
| `test/CMakeLists.txt` | Test build | ❌ No (optional) |
| `build.sh` | Convenience script | ❌ No (can run cmake manually) |

### File Relationships

```
Configuration Files:
    vcpkg.json → Declares dependencies
    CMakePresets.json → Simplifies cmake commands
    .gitignore → Excludes generated files

Build System:
    CMakeLists.txt (4 files) → Define build rules
    vcpkg.cmake → Integrates package manager

Source Code:
    libsdb.hpp → Public API
    libsdb.cpp → Implementation
    sdb.cpp → User interface
    tests.cpp → Test cases

Automation:
    build.sh → Build everything
    clean.sh → Remove artifacts
    run.sh → Execute program
    test.sh → Run tests
```

---

This completes the detailed explanation of all files in the project!