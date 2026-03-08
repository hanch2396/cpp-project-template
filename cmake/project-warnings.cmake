add_library(project-warnings INTERFACE)

# 기본 경고 옵션
target_compile_options(
  project-warnings
  INTERFACE
  -Wall # 기본 경고
  -Wextra # 추가 경고
  -Wpedantic # 표준 준수
  -Wshadow # 바깥 스코프의 변수명과 안쪽 스코프의 변수명이 같아 가려지는 현상(Shadowing)을 경고
  -Wformat=2 # 보안 관련 포맷 스트링 검사 강화
)

# C++ 클래스/객체지향 관련 안전장치
target_compile_options(
  project-warnings
  INTERFACE
  -Wnon-virtual-dtor # 가상 소멸자 누락 방지 (메모리 누수 예방)
  -Woverloaded-virtual # 가상 함수 가림(Hiding) 방지
)

# GCC 컴파일러 전용 강력한 검사 (Clang에서는 지원 안 할 수 있음)
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  target_compile_options(
    project-warnings
    INTERFACE
    -Wlogical-op # 논리 연산자 실수 방지
    -Wduplicated-cond # 중복된 조건문 검사 (복붙 에러 방지)
    -Wduplicated-branches # 중복된 브랜치 내용 검사 (조건은 다르지만 내부 내용이 같을 때)
    -Wnull-dereference # 명백한 NULL 참조 방지
  )
endif()

# Release 모드에서만 경고를 에러로 처리
target_compile_options(
  project-warnings
  INTERFACE
  $<$<CONFIG:Release>:-Werror>
)
