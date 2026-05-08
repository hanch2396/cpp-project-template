#=================================================
# 모듈 예제
#=================================================
add_library(my-libs)

target_sources(my-libs 
  # 모듈 인터페이스 파일
  PUBLIC
    FILE_SET cxx_modules # `cxx_modules` 말고 원하는 이름으로 변경 가능
    TYPE CXX_MODULES # 모듈 인터페이스 파일임을 명시 (필수!)
    FILES # 모듈 인터페이스 파일 나열
      my-class.cppm

  # 모듈 인터페이스 구현 파일 (모듈 인터페이스와 구현을 분리하는 경우)
  PRIVATE
    my-class.cpp
)
#=================================================

add_executable(example)

target_sources(example PRIVATE
  main.cpp
)

target_link_libraries(example PRIVATE
  project-warnings
  my-libs
)

install(TARGETS example DESTINATION bin)
