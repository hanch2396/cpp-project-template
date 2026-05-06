add_library(math)

target_sources(math PUBLIC
  FILE_SET cxx_modules
  TYPE CXX_MODULES
  FILES
  math.cppm
)

target_sources(math PRIVATE
  math.cpp
)

add_executable(example)

target_sources(example PRIVATE
  main.cpp
)

target_link_libraries(example PRIVATE
  project-warnings
  math
)

install(TARGETS example DESTINATION bin)
