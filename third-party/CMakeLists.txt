list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/third-party/cmake")

# include(fmt)
add_library(third-party INTERFACE)

target_link_libraries(third-party INTERFACE

  # fmt::fmt
)
