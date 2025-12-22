cmake_minimum_required(VERSION 3.16)
project(nixos-discover-backend)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 REQUIRED COMPONENTS Core Network)
find_package(KF6 REQUIRED COMPONENTS CoreAddons I18n)

# Find Discover's library
find_package(PkgConfig REQUIRED)
pkg_check_modules(DISCOVER discover)

set(nixos-backend_SRCS
    NixOSBackend.cpp
    NixOSResource.cpp
    NixOSUpdater.cpp
    NixOSTransaction.cpp
)

kcoreaddons_add_plugin(nixos-backend
    SOURCES ${nixos-backend_SRCS}
    INSTALL_NAMESPACE "discover"
)

target_include_directories(nixos-backend PRIVATE
    ${DISCOVER_INCLUDE_DIRS}
)

target_link_libraries(nixos-backend
    Qt6::Core
    Qt6::Network
    KF6::CoreAddons
    KF6::I18n
    ${DISCOVER_LIBRARIES}
)
