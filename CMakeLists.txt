#-------------------------------------------------------------------------------
#CMake Configuration for HPC Fortran Project
#Compiler Support: Intel oneAPI ifx + NVIDIA nvfortran
#-------------------------------------------------------------------------------

#===============================================================================
# CMakeLists.txt Organization
#
# This file is organized into clearly defined sections to improve readability,
# maintainability, and long-term scalability. Each section groups related CMake
# commands, making it easier to locate build settings, understand the project
# structure, and extend the build system as the project evolves.
#===============================================================================

#==============================================================================
# Section 1: Project
#
# Define the minimum required CMake version and initialize the project.
# This section establishes the project identity, version information,
# supported programming languages, and metadata used throughout the build.
#==============================================================================
cmake_minimum_required(VERSION 3.18)

project(
    Compiler-driven-Parallelism-Fortran-DO-CONCURRENT
    VERSION 1.0.0
    DESCRIPTION "Compiler-Driven-Parallelism-Fortran-PDE-Solver"
    LANGUAGES Fortran
)

#===============================================================================
# Section 2: Build Settings
#
# Define configurable build options that control how the project is compiled.
# This section contains user-selectable settings, such as enabling language
# features and choosing the build configuration, without modifying the build
# logic elsewhere in the project.
#===============================================================================

option(USE_DOUBLE_PRECISION
    "Use double precision for floating-point calculations"
    OFF
)

set(CMAKE_BUILD_TYPE
    Release
    CACHE STRING
    "Build type"
)

set_property(
    CACHE CMAKE_BUILD_TYPE
    PROPERTY STRINGS
    Debug
    Release
    RelWithDebInfo
    Profile
)

#===============================================================================
# Section 3: Compiler Detection
#
# Identify the active Fortran compiler and configure compiler-specific
# settings. The build proceeds only with supported compilers to ensure
# compatibility and consistent behavior across the project.
#===============================================================================

message(STATUS "Compiler : ${CMAKE_Fortran_COMPILER_ID}")
if(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
    set(COMPILER_NAME "Intel oneAPI ifx")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "NVHPC|NVIDIA|PGI")
    set(COMPILER_NAME "NVIDIA HPC SDK")
else()
    message(FATAL_ERROR
        "Unsupported compiler : ${CMAKE_Fortran_COMPILER_ID}"
    )
endif()
message(STATUS "Using ${COMPILER_NAME}")

#===============================================================================
# Section 4: Compiler Flags
#
# Define compiler-specific compilation flags for different build
# configurations. This section centralizes optimization, debugging,
# warning, and profiling options to ensure a consistent and maintainable
# build configuration.
#===============================================================================

#   INTEL
if(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")

    if(WIN32)

        set(COMMON_FLAGS)

        set(OPT_FLAGS
            /O2
            /QxHost
        )

        set(DEBUG_FLAGS
            /Od
            /debug:full
            /traceback
        )

        set(PROFILE_FLAGS
            /pg
            /debug:full
        )

        set(REPORT_FLAGS
            /Qopt-report:3
            /Qopt-report-phase:openmp,vec,loop
        )

        set(IFX_DO_CONCURRENT_FLAGS
            /Qopenmp
        )

    else()

        set(COMMON_FLAGS
            -fpp
        )

        set(OPT_FLAGS
            -O3
            -xHost
        )

        set(DEBUG_FLAGS
            -O0
            -g
            -traceback
        )

        set(PROFILE_FLAGS
            -pg
            -g
        )

        set(REPORT_FLAGS
            -qopt-report=3
            -qopt-report-phase=openmp,vec,loop
        )

        set(IFX_DO_CONCURRENT_FLAGS
            -qopenmp
        )

    endif()

endif()


#    NVIDIA
#==========================
if(CMAKE_Fortran_COMPILER_ID MATCHES "NVHPC|NVIDIA|PGI")

    set(COMMON_FLAGS
        -Mbackslash
        -Mstandard
        -Mallocatable=03
        -Mfree
	-Mpreprocess
    )

    set(OPT_FLAGS
        -O3
        -Mvect
        -Mprefetch
        -Mfprelaxed
        -Mautoinline
        -Minline
    )

    set(DEBUG_FLAGS
        -O0
        -g
        -Mbounds
    )

    set(PROFILE_FLAGS
        -Mprof=func
    )

    set(REPORT_FLAGS
        -Minfo=all

    )

    # Standard parallelism (DO CONCURRENT)
    set(NVHPC_DO_CONCURRENT_FLAGS
        -stdpar=multicore
    )
endif()

#===============================================================================
# Section 5: Build Configuration
#
# Assemble the final set of compiler options according to the selected
# build type. Each configuration combines the appropriate optimization,
# debugging, profiling, and reporting flags into a single list that is
# applied to the project target.
#===============================================================================

set(PROJECT_COMPILE_OPTIONS)
list(APPEND PROJECT_COMPILE_OPTIONS
    ${COMMON_FLAGS}
)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    list(APPEND PROJECT_COMPILE_OPTIONS
        ${OPT_FLAGS}
        ${REPORT_FLAGS}
    )

elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND PROJECT_COMPILE_OPTIONS
        ${DEBUG_FLAGS}
    )

elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    list(APPEND PROJECT_COMPILE_OPTIONS
        ${OPT_FLAGS}
        ${REPORT_FLAGS}
        ${RELWITHDEBINFO_FLAGS}
    )

elseif(CMAKE_BUILD_TYPE STREQUAL "Profile")
    list(APPEND PROJECT_COMPILE_OPTIONS
        ${OPT_FLAGS}
        ${PROFILE_FLAGS}
        ${REPORT_FLAGS}
    )
endif()

#===============================================================================
# Section 6: DO CONCURRENT Configuration
#
# Configure compiler options required to enable compiler-driven parallelism
# using the Fortran DO CONCURRENT construct. Although different compilers
# require different flags, the programming model remains standard Fortran.
#===============================================================================

if(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
    list(APPEND PROJECT_COMPILE_OPTIONS ${IFX_DO_CONCURRENT_FLAGS})
    list(APPEND PROJECT_LINK_OPTIONS    ${IFX_DO_CONCURRENT_FLAGS})

elseif(CMAKE_Fortran_COMPILER_ID MATCHES "NVHPC|NVIDIA|PGI")
    list(APPEND PROJECT_COMPILE_OPTIONS ${NVHPC_DO_CONCURRENT_FLAGS})
    list(APPEND PROJECT_LINK_OPTIONS    ${NVHPC_DO_CONCURRENT_FLAGS})
endif()

#===============================================================================
# Compiler Parallelization
#
# Display the compiler-specific implementation used to enable parallel
# execution of the standard Fortran DO CONCURRENT construct.
#===============================================================================

if(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
    message(STATUS "DO CONCURRENT enabled using Intel ifx.")

elseif(CMAKE_Fortran_COMPILER_ID MATCHES "NVHPC|NVIDIA|PGI")
    message(STATUS "DO CONCURRENT enabled using NVIDIA HPC SDK.")

endif()

#===============================================================================
# Section 7: Source Directories
#
# Define the project's source code directories. Centralizing directory paths
# improves readability, simplifies maintenance, and avoids hard-coded paths
# throughout the build configuration.
#===============================================================================

set(SRC_DIR "${CMAKE_SOURCE_DIR}/src")
set(APP_DIR "${CMAKE_SOURCE_DIR}/app")

#===============================================================================
# Section 8: Source Files
#
# Collect the source files required to build the project executable.
# Keeping the source list in a dedicated section provides a clear overview
# of the project structure and simplifies adding or removing source files.
#===============================================================================

set(MODULE_SOURCES
    ${SRC_DIR}/precisions_control.f90
    ${SRC_DIR}/error_handler.f90
    ${SRC_DIR}/performance_timer.f90
    ${SRC_DIR}/simulation_config.f90
    ${SRC_DIR}/core_utilities.f90
    ${SRC_DIR}/phase_field_core.f90
    ${SRC_DIR}/grid_setup.f90
    ${SRC_DIR}/grid_generator.f90
    ${SRC_DIR}/microstructure_initializer.f90
    ${SRC_DIR}/free_energy_kernel.f90
    ${SRC_DIR}/laplacian_kernel.f90
    ${SRC_DIR}/time_kernel.f90
    ${SRC_DIR}/io_handlers.f90
    ${SRC_DIR}/performance_analyzer.f90
    ${SRC_DIR}/performance_evaluation.f90
)

set(MAIN_SOURCE
    ${APP_DIR}/main_driver.f90
)

#===============================================================================
# Section 9: Executable
#
# Define the project executable and associate it with the project's source
# files. This section establishes the primary build target that will be
# compiled and linked by CMake.
#===============================================================================

add_executable(
    cahn_hilliard_driver
    ${MAIN_SOURCE}
    ${MODULE_SOURCES}
)

#===============================================================================
# Section 10: Apply Compiler Options
#
# Apply the configured compiler, linker, and preprocessor settings to the
# project target. This section consolidates all previously defined build
# options into the executable configuration.
#===============================================================================

target_compile_options(
    cahn_hilliard_driver
    PRIVATE
    ${PROJECT_COMPILE_OPTIONS}
)

#===============================================================================
# Section 11: Apply Linker Options
#
# Apply the required linker options to the project executable. This section
# ensures that compiler-specific runtime libraries and linker flags are
# correctly configured for the selected build configuration.
#===============================================================================

target_link_options(
    cahn_hilliard_driver
    PRIVATE
    ${PROJECT_LINK_OPTIONS}
)


#===============================================================================
# Section 12: Compile Definitions
#===============================================================================

if(USE_DOUBLE_PRECISION)
    target_compile_definitions(
        cahn_hilliard_driver
        PRIVATE
        USE_DOUBLE_PRECISION
    )
endif()

#===============================================================================
# Section 13: Target Properties
#
# Configure properties of the project executable, including the output
# locations for generated module files and the executable. Keeping these
# settings centralized ensures a clean and organized build directory.
#===============================================================================

set_target_properties(
    cahn_hilliard_driver
    PROPERTIES
        Fortran_MODULE_DIRECTORY
            ${PROJECT_BINARY_DIR}/modules
        RUNTIME_OUTPUT_DIRECTORY
            ${PROJECT_BINARY_DIR}/bin
)

#===============================================================================
# Section 14: Optimization Reports
#
# Display post-build information related to compiler-generated optimization
# reports. This section provides convenient reminders about the availability
# and location of performance analysis reports produced during compilation.
#===============================================================================

if(CMAKE_Fortran_COMPILER_ID MATCHES "NVHPC|NVIDIA|PGI")
    add_custom_command(
        TARGET cahn_hilliard_driver
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMAND ${CMAKE_COMMAND} -E echo "Optimization reports generated."
        COMMAND ${CMAKE_COMMAND} -E echo "See *.lst files."
    )
endif()

#===============================================================================
# Section 15: Build Summary
#
# Display a concise summary of the project configuration after CMake
# completes its configuration step. This provides a quick overview of the
# selected compiler, build settings, and output locations.
#===============================================================================

message(STATUS "")
message(STATUS "====================================================")
message(STATUS " Project        : ${PROJECT_NAME}")
message(STATUS " Version        : ${PROJECT_VERSION}")
message(STATUS " Compiler       : ${COMPILER_NAME}")
message(STATUS " Build Type     : ${CMAKE_BUILD_TYPE}")
message(STATUS " System         : ${CMAKE_SYSTEM_NAME}")
message(STATUS "")
message(STATUS " Parallel Programming Model")
message(STATUS "   Standard Fortran (DO CONCURRENT)")
message(STATUS "")
message(STATUS " Output")
message(STATUS "   Executable   : ${PROJECT_BINARY_DIR}/bin")
message(STATUS "   Modules      : ${PROJECT_BINARY_DIR}/modules")
message(STATUS "====================================================")
message(STATUS "")