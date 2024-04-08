cmake_minimum_required(VERSION 3.10)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project(hello VERSION 1.0)
add_executable(main main.cpp)
include_directories("$ENV{HOME}/.local/include/c++/") # NOTE: extra header dir, make this work: `include<bits/stdc++.h>`
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_DEBUG -O1")
