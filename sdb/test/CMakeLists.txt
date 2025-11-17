find_package(Catch2 CONFIG REQUIRED)

add_executable(sdb-tests tests.cpp)

target_link_libraries(sdb-tests PRIVATE 
    sdb::libsdb
    Catch2::Catch2WithMain
)

include(CTest)
include(Catch)
catch_discover_tests(sdb-tests)