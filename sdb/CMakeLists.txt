cmake_minimum_required(VERSION 3.14)
project(sdb VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find libedit from vcpkg using pkg-config
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