# plugins/FriendsMap/CMakeLists.txt
cmake_minimum_required(VERSION 3.18)
project(FriendMapPlugin LANGUAGES C CXX)

# ---------------------------------------------------------------------------
# Qt: same detection as retroshare-gui (Qt6 first, then Qt5).
# Force Qt5 with -DCMAKE_DISABLE_FIND_PACKAGE_Qt6=ON.
# RetroShare, Marble and this plugin must all use the same Qt major version.
# ---------------------------------------------------------------------------
if(NOT DEFINED QT_VERSION_MAJOR)
    find_package(Qt6 QUIET COMPONENTS Core)
    if(Qt6_FOUND)
        set(QT_VERSION_MAJOR 6)
    else()
        find_package(Qt5 COMPONENTS Core REQUIRED)
        set(QT_VERSION_MAJOR 5)
    endif()
endif()
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Gui Widgets REQUIRED)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

get_filename_component(RS_SUPERPROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
# Folder that holds the RetroShare checkout (and, on Windows, marble/ and geoip-api-c/)
get_filename_component(RS_PARENT_DIR "${RS_SUPERPROJECT_ROOT}/.." ABSOLUTE)

# ---------------------------------------------------------------------------
# Plugin sources
# ---------------------------------------------------------------------------
set(FRIENDMAP_SOURCES
    FriendMapPlugin.cpp
    FriendMapPage.cpp
    PaintLayer.cpp
    FriendMapSettings.cpp
    FriendMapConfigPage.cpp
    FriendMapDetached.cpp
    FriendMapController.cpp
)

set(FRIENDMAP_HEADERS
    FriendMapPlugin.h
    FriendMapPage.h
    MarbleWidget.h
    PaintLayer.h
    FriendMapSettings.h
    FriendMapConfigPage.h
    FriendMapDetached.h
    FriendMapController.h
)

set(FRIENDMAP_FORMS
    FriendMapPage.ui
    FriendMapConfigPage.ui
    FriendMapDetached.ui
)

set(FRIENDMAP_RESOURCES
    fmimages.qrc
)

# ---------------------------------------------------------------------------
# GeoIP
#  Windows: compile the geoip-api-c sources directly (no library needed).
#  Linux/macOS: use the system libGeoIP (libgeoip-dev).
# ---------------------------------------------------------------------------
if(WIN32)
    set(GEOIP_SRC_DIR "${RS_PARENT_DIR}/geoip-api-c/libGeoIP" CACHE PATH
        "Path to geoip-api-c/libGeoIP sources")
    if(NOT EXISTS "${GEOIP_SRC_DIR}/GeoIP.c")
        message(FATAL_ERROR
            "GeoIP sources not found in ${GEOIP_SRC_DIR}. Clone "
            "https://github.com/maxmind/geoip-api-c next to RetroShare, or set "
            "-DGEOIP_SRC_DIR=<path to geoip-api-c/libGeoIP>.")
    endif()
    set(GEOIP_SOURCES
        "${GEOIP_SRC_DIR}/GeoIP.c"
        "${GEOIP_SRC_DIR}/GeoIPCity.c"
        "${GEOIP_SRC_DIR}/GeoIP_deprecated.c"
    )
    # Only the GeoIP C files need these (same as FriendMap.pro)
    set_source_files_properties(${GEOIP_SOURCES} PROPERTIES
        COMPILE_DEFINITIONS "WINVER=0x0501;_WIN32_WINNT=0x0501;PACKAGE_VERSION=\"1.6\"")
    set(GEOIP_INCLUDE_DIR "${GEOIP_SRC_DIR}")
else()
    find_path(GEOIP_INCLUDE_DIR GeoIP.h)
    find_library(GEOIP_LIBRARY NAMES GeoIP)
    if(NOT GEOIP_INCLUDE_DIR OR NOT GEOIP_LIBRARY)
        message(FATAL_ERROR "libGeoIP not found (install libgeoip-dev).")
    endif()
endif()

# ---------------------------------------------------------------------------
# Marble (library name: marblewidget-qt5 or marblewidget-qt6)
# ---------------------------------------------------------------------------
if(WIN32)
    set(_marble_default "${RS_PARENT_DIR}/marble/install")
else()
    set(_marble_default "")
endif()
set(MARBLE_DIR "${_marble_default}" CACHE PATH
    "Marble install prefix (the folder that contains include/marble and lib)")

find_path(MARBLE_INCLUDE_DIR marble/MarbleWidget.h
          HINTS "${MARBLE_DIR}/include")
find_library(MARBLE_LIBRARY NAMES marblewidget-qt${QT_VERSION_MAJOR}
             HINTS "${MARBLE_DIR}/lib" "${MARBLE_DIR}")

if(NOT MARBLE_INCLUDE_DIR OR NOT MARBLE_LIBRARY)
    message(FATAL_ERROR
        "Marble for Qt${QT_VERSION_MAJOR} not found (looked for marble/MarbleWidget.h and "
        "libmarblewidget-qt${QT_VERSION_MAJOR} in '${MARBLE_DIR}'). Build and install Marble "
        "with the same Qt version (see readme.md), or set -DMARBLE_DIR=<install prefix>.")
endif()
message(STATUS "FriendMap: Qt${QT_VERSION_MAJOR}, Marble ${MARBLE_LIBRARY}")

# ---------------------------------------------------------------------------
# Target
# ---------------------------------------------------------------------------
add_library(FriendMap MODULE
    ${FRIENDMAP_SOURCES}
    ${FRIENDMAP_HEADERS}
    ${FRIENDMAP_FORMS}
    ${FRIENDMAP_RESOURCES}
    ${GEOIP_SOURCES}
)

set_target_properties(FriendMap PROPERTIES
    PREFIX "lib"
    CXX_STANDARD 17
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/plugins"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/plugins"
)

target_include_directories(FriendMap PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${GEOIP_INCLUDE_DIR}
    ${MARBLE_INCLUDE_DIR}
    ${RS_SUPERPROJECT_ROOT}/libretroshare/src
    ${RS_SUPERPROJECT_ROOT}/retroshare-gui/src
    ${RS_SUPERPROJECT_ROOT}/retroshare-gui/src/gui
    ${RS_SUPERPROJECT_ROOT}/supportlibs/rapidjson/include
)

target_link_libraries(FriendMap PRIVATE
    ${MARBLE_LIBRARY}
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::Widgets
)

if(WIN32)
    target_compile_definitions(FriendMap PRIVATE WINDOWS_SYS)
    target_link_libraries(FriendMap PRIVATE ws2_32)

    # A Windows DLL must resolve every symbol at link time, so link RetroShare
    # itself. In the super-project the targets exist; standalone, use the
    # import libraries of a RetroShare CMake build tree (see RetroChess).
    if(TARGET retroshare AND TARGET retroshare-gui)
        target_link_libraries(FriendMap PRIVATE retroshare retroshare-gui)
    else()
        set(RS_BUILD_DIR "${RS_SUPERPROJECT_ROOT}/Build-cmake" CACHE PATH
            "RetroShare build directory to link against when building standalone")

        find_library(RS_LIBRETROSHARE_IMPLIB NAMES retroshare
                     HINTS "${RS_BUILD_DIR}/libretroshare" NO_DEFAULT_PATH)
        find_library(RS_GUI_IMPLIB NAMES retroshare-gui
                     HINTS "${RS_BUILD_DIR}/retroshare-gui" NO_DEFAULT_PATH)

        if(NOT RS_LIBRETROSHARE_IMPLIB OR NOT RS_GUI_IMPLIB)
            message(FATAL_ERROR
                "Standalone Windows build needs the import libraries of a built "
                "RetroShare. Looked in ${RS_BUILD_DIR} for libretroshare.dll.a and "
                "libretroshare-gui.dll.a. Build RetroShare first, or point "
                "-DRS_BUILD_DIR=<its build directory> at it.")
        endif()

        message(STATUS "FriendMap: standalone Windows link against ${RS_BUILD_DIR}")
        target_link_libraries(FriendMap PRIVATE
            "${RS_LIBRETROSHARE_IMPLIB}" "${RS_GUI_IMPLIB}")
    endif()
else()
    target_link_libraries(FriendMap PRIVATE ${GEOIP_LIBRARY})
endif()

target_compile_definitions(FriendMap PRIVATE RS_NO_WARN_DEPRECATED)

# Must match the host build (see RetroChess/CMakeLists.txt): RS_USE_CALENDAR
# changes the layout of RsPlugInInterfaces.
option(RS_USE_CALENDAR "Build against a RetroShare with the GXS Calendar service" ON)
if(RS_USE_CALENDAR)
    target_compile_definitions(FriendMap PRIVATE RS_USE_CALENDAR)
endif()

target_compile_options(FriendMap PRIVATE
    $<$<COMPILE_LANG_AND_ID:CXX,GNU>:-Wall;-Wextra;-Wno-deprecated-declarations>
    $<$<AND:$<COMPILE_LANG_AND_ID:CXX,GNU>,$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,15>>:-Wno-template-body>
)

install(TARGETS FriendMap DESTINATION lib/retroshare/plugins)
