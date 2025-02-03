cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
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
# add_dependencies(${BINARY_NAME} flutter_assemble)

# ================================================
# register service to the system
set(INDEPENDENT_EXE "CloudPlayPlusSVC")

# 2. 添加新可执行文件（假设源代码在项目根目录的tools/子目录）
add_executable(${INDEPENDENT_EXE}
  serviceRegister/cloudplayplussvc.cpp # 其他源文件
)

# 3. 配置独立编译选项（可选）
set_target_properties(${INDEPENDENT_EXE} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
  OUTPUT_NAME "CloudPlayPlusSVC"  # 生成的可执行文件名称
)

# 4. 指定独立依赖（如需要）
#target_link_libraries(${INDEPENDENT_EXE} PRIVATE
  #user32.lib       # Windows API库
#)

# 6. 确保与Flutter构建的依赖隔离
if(TARGET flutter_assemble)
  add_dependencies(${BINARY_NAME} flutter_assemble) # 原Flutter依赖不变
  # 注意：独立可执行文件不要添加flutter_assemble依赖
endif()

add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_CURRENT_SOURCE_DIR}/serviceRegister/service.bat"
        "$<TARGET_FILE_DIR:${BINARY_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_CURRENT_SOURCE_DIR}/serviceRegister/unregisterservice.bat"
        "$<TARGET_FILE_DIR:${BINARY_NAME}>"
    COMMENT "Copying serviceRegister files to Flutter output"
)