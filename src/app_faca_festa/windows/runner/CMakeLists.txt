cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "desktop_updater.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

include(FetchContent)
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()
FetchContent_Declare(winsparkle
  URL "https://github.com/vslavik/winsparkle/releases/download/v0.9.4/WinSparkle-0.9.4.zip"
  URL_HASH SHA256=6037df37fc263bd1650a1c4949681a9d40ffe991d01f35892a406cb5d103c976)
FetchContent_MakeAvailable(winsparkle)
set(WINSPARKLE_DIR "${winsparkle_SOURCE_DIR}")
if(EXISTS "${WINSPARKLE_DIR}/WinSparkle-0.9.4/include")
  set(WINSPARKLE_DIR "${WINSPARKLE_DIR}/WinSparkle-0.9.4")
endif()
target_compile_options(${BINARY_NAME} PRIVATE /utf-8)
target_include_directories(${BINARY_NAME} PRIVATE "${WINSPARKLE_DIR}/include")
target_link_libraries(${BINARY_NAME} PRIVATE "${WINSPARKLE_DIR}/x64/Release/WinSparkle.lib" bcrypt version)
add_executable(faca_festa_update_helper WIN32 "update_helper.cpp")
apply_standard_settings(faca_festa_update_helper)
target_link_libraries(faca_festa_update_helper PRIVATE bcrypt shell32)
set(WINSPARKLE_DIR "${WINSPARKLE_DIR}" PARENT_SCOPE)
add_executable(faca_festa_update_smoke EXCLUDE_FROM_ALL "../../tool/desktop_update_smoke.cpp")
apply_standard_settings(faca_festa_update_smoke)
target_compile_options(faca_festa_update_smoke PRIVATE /utf-8)
target_include_directories(faca_festa_update_smoke PRIVATE "${WINSPARKLE_DIR}/include")
target_link_libraries(faca_festa_update_smoke PRIVATE "${WINSPARKLE_DIR}/x64/Release/WinSparkle.lib" bcrypt)
set_target_properties(faca_festa_update_smoke PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/updater-smoke")
