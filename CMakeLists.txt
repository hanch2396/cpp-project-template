cmake_minimum_required(VERSION 4.0.0)

# C++23 표준의 `import std;`를 사용하기 위해 CMake의 실험적 기능 활성화
# CMake 마이너 업데이트마다 UUID 값이 달라지므로 CMake 업데이트 시 아래 링크에서 UUID 값 확인 필요
# https://github.com/Kitware/CMake/blob/master/Help/dev/experimental.rst#c-import-std-support
set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD "f35a9ac6-8463-4d38-8eec-5d6008153e7d")

project(
  cpp-project-template
  VERSION 0.1.0
  LANGUAGES C CXX
)

# set(CMAKE_CXX_STANDARD 23)
# set(CMAKE_CXX_STANDARD_REQUIRED ON)
# set(CMAKE_CXX_EXTENSIONS OFF)
# set(CMAKE_CXX_MODULE_STD ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

message("")
message("OS: ${CMAKE_HOST_SYSTEM_NAME}")

set(FETCHCONTENT_BASE_DIR "${CMAKE_BINARY_DIR}/fetch-content")

# 컴파일 옵션 백업
set(CMAKE_CXX_FLAGS_ORIGINAL ${CMAKE_CXX_FLAGS})

# 서드파티 라이브러리에 대한 경고 제거.
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -w")
# 밑에서 third-party 서브 디렉토리에 SYSTEM을 추가하여 
# 라이브러리 헤더 대한 경고는 제거했지만
# 라이브러리 내부 소스코드에 대한 경고는 제거할 수 없으므로
# -w 옵션을 추가하여 소스코드에 대한 경고도 제거한다.

# 시스템 헤더로 처리하여 컴파일 경고 제거.
add_subdirectory(third-party SYSTEM)
# 현재 전역 컴파일러 경고를 project-warnings 타겟으로 만들고
# project-warnings 타겟을 다른 타겟이 링크하는 방식으로 변경하여 프로젝트 전역에서
# 컴파일러 경고가 발생하지 않는다.
# 따라서 서브디렉토리의 SYSTEM 옵션만 설정해도 컴파일 에러가 발생하지 않지만
# 컴파일 메시지를 깔끔하게 유지하기 위해 -w 옵션을 계속 사용한다.

# 컴파일 옵션 복구
set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS_ORIGINAL})

# 6. 컴파일러 옵션 설정
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  message(STATUS "Using compiler: ${CMAKE_CXX_COMPILER_ID}")

  # 컴파일러 경고 타겟 설정
  include(project-warnings)

  if (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    link_libraries(stdc++exp)
  endif()

else()
  message(WARNING "Unknown compiler: ${CMAKE_CXX_COMPILER_ID}")
endif()

get_directory_property(CURRENT_DIR_COMPILE_OPTIONS COMPILE_OPTIONS)

message("CMake CXX Compiler ID: ${CMAKE_CXX_COMPILER_ID}")
message("CMake CXX Compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
message("CMake CXX Compiler options: ${CURRENT_DIR_COMPILE_OPTIONS}")
message("")

add_subdirectory(src)

include(copy_compile_commands)
