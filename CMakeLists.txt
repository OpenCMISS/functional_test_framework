
cmake_minimum_required(VERSION 3.4 FATAL_ERROR)
project(OpenCMISS-FunctionalTests VERSION 1.0 LANGUAGES C CXX Fortran)

# Default values for test database.
set(TEST_DB_GIT_BASE https://github.com)
set(TEST_DB_ORG OpenCMISS)
set(TEST_DB_REPO_NAME functional_test_database)
set(TEST_DB_REPO_URL ${TEST_DB_GIT_BASE}/${TEST_DB_ORG}/${TEST_DB_REPO_NAME})
set(TEST_DB_REPO_BRANCH develop)

if (NOT DEFINED TEST_DB)
    set(TEST_DB "${CMAKE_CURRENT_BINARY_DIR}/test_db/")
endif ()
set(TEST_DB ${TEST_DB} CACHE PATH "Set the test database.")

# Default values for ndiff.
set(NDIFF_GIT_BASE https://github.com)
set(NDIFF_ORG OpenCMISS-Utilities)
set(NDIFF_REPO_NAME ndiff)
set(NDIFF_REPO_BRANCH v2.0.0)

if (DEFINED BUILD_TYPE)
    set(CMAKE_BUILD_TYPE ${BUILD_TYPE} CACHE STRING "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
else ()
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel.")
endif ()

#find_package(OpenCMISSLibs REQUIRED)
set(OpenCMISSLibs_DIR ${OpenCMISSLibs_DIR} CACHE PATH "Install prefix for OpenCMISS libraries.")

# Basic test for multi-configuration capable environments.
if (MSVC OR XCODE)
    set(_MULTI_CONFIG_ENV TRUE)
else ()
    set(_MULTI_CONFIG_ENV FALSE)
endif ()

if (_MULTI_CONFIG_ENV)
    set(MULTICONFIG_BUILD_CONFIG --config $<CONFIGURATION>)
else ()
    set(SINGLE_ARCHITECUTRE_BUILD_TYPE -release)
    set(SINGLE_BUILD_CONFIG -DCMAKE_BUILD_TYPE=Release)
endif ()

if (OPENCMISS_MPI)
    set(OPENCMISS_MPI_CONFIGURATION -DOPENCMISS_MPI=${OPENCMISS_MPI})
else ()
    set(OPENCMISS_MPI_CONFIGURATION -UOPENCMISS_MPI)
endif ()

# Get ndiff installed.
set(NDIFF_REPO_URL ${NDIFF_GIT_BASE}/${NDIFF_ORG}/${NDIFF_REPO_NAME})
set(NDIFF_CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=.)

include(ExternalProject)

ExternalProject_Add(ndiff
    PREFIX ndiff
    STAMP_DIR ndiff/stamp
    TMP_DIR ndiff/tmp
    SOURCE_DIR ndiff/src
    BINARY_DIR ndiff/build
    GIT_REPOSITORY ${NDIFF_REPO_URL}
    GIT_TAG ${NDIFF_REPO_BRANCH}
    CMAKE_COMMAND ${CMAKE_COMMAND}
    CMAKE_ARGS ${SINGLE_BUILD_CONFIG} ${NDIFF_CMAKE_ARGS}
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install ${MULTICONFIG_BUILD_CONFIG}
)

set(OCMERGE_DEPEND "")

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)

    # Default values for ocmerge.
    set(OCMERGE_GIT_BASE https://github.com)
    set(OCMERGE_ORG OpenCMISS-Utilities)
    set(OCMERGE_REPO_NAME ocmerge)
    set(OCMERGE_REPO_BRANCH 1.0.0)
    set(OCMERGE_REPO_URL ${OCMERGE_GIT_BASE}/${OCMERGE_ORG}/${OCMERGE_REPO_NAME})
    set(OCMERGE_CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=.)

    ExternalProject_Add(ocmerge
        PREFIX ocmerge
        STAMP_DIR ocmerge/stamp
        TMP_DIR ocmerge/tmp
        SOURCE_DIR ocmerge/src
        BINARY_DIR ocmerge/build
        GIT_REPOSITORY ${OCMERGE_REPO_URL}
        GIT_TAG ${OCMERGE_REPO_BRANCH}
        CMAKE_COMMAND ${CMAKE_COMMAND}
        CMAKE_ARGS ${SINGLE_BUILD_CONFIG} ${OCMERGE_CMAKE_ARGS}
        BUILD_COMMAND ""
        INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install ${MULTICONFIG_BUILD_CONFIG}
    )
    set(OCMERGE_DEPEND ocmerge)
endif ()

MESSAGE(STATUS "*** DB TAG: ${TEST_DB_REPO_BRANCH}")

ExternalProject_Add(test_db
    SOURCE_DIR test_db/
    GIT_REPOSITORY ${TEST_DB_REPO_URL}
    GIT_TAG ${TEST_DB_REPO_BRANCH}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

if (NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/testacquire-build")
    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/testacquire-build)
endif ()
if (NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/testsetup-build")
    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/testsetup-build)
endif ()
if (NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/testrunner-build")
    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/testrunner-build)
endif ()
if (NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/CTestTestfile.cmake")
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/CTestTestfile.cmake" "# Generated test configuration file.\r\nsubdirs(\"testrunner-build\")\r\n")
endif ()

add_custom_target(acquire_tests
    COMMAND ${CMAKE_COMMAND}
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/Modules
        -DTEST_DB=${TEST_DB}
        -DTESTS_BASE_DIR=${CMAKE_CURRENT_BINARY_DIR}/tests
        ${CMAKE_CURRENT_SOURCE_DIR}/testacquire
    COMMAND ${CMAKE_COMMAND} --build . ${MULTICONFIG_BUILD_CONFIG}
    DEPENDS test_db
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/testacquire-build)

add_custom_target(setup_tests
    COMMAND ${CMAKE_COMMAND}
        ${OPENCMISS_MPI_CONFIGURATION}
        -DOpenCMISSLibs_DIR=${OpenCMISSLibs_DIR}
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/Modules
        -DTEST_DB=${TEST_DB}
        -DNDIFF_EXECUTABLE=${CMAKE_CURRENT_BINARY_DIR}/ndiff/build/bin/ndiff
        -DOCMERGE_EXECUTABLE=${CMAKE_CURRENT_BINARY_DIR}/ocmerge/build/bin/ocmerge
        -DTESTS_BASE_DIR=${CMAKE_CURRENT_BINARY_DIR}/tests
        ${CMAKE_CURRENT_SOURCE_DIR}/testsetup
    COMMAND ${CMAKE_COMMAND} --build . ${MULTICONFIG_BUILD_CONFIG}
    DEPENDS ndiff ${OCMERGE_DEPEND} acquire_tests
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/testsetup-build)

add_custom_target(build_tests
    COMMAND ${CMAKE_COMMAND} ${CMAKE_CURRENT_BINARY_DIR}/tests
    COMMAND ${CMAKE_COMMAND} --build . ${MULTICONFIG_BUILD_CONFIG}
    DEPENDS setup_tests
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/testrunner-build)

add_custom_target(run_tests ALL
    COMMAND ${CMAKE_CTEST_COMMAND}
    DEPENDS build_tests
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

add_custom_target(clear_tests
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_BINARY_DIR}/testacquire-build
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/testacquire-build
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_BINARY_DIR}/testsetup-build
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/testsetup-build
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_BINARY_DIR}/testrunner-build
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/testrunner-build
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_BINARY_DIR}/tests)

set(ADVANCED_GUI_ENTRIES)
list(APPEND ADVANCED_GUI_ENTRIES BLAS_DIR BZip2_DIR CELLML_DIR CSim_DIR Clang_DIR FIELDML-API_DIR FTGL_DIR Fieldml-API_DIR)
list(APPEND ADVANCED_GUI_ENTRIES Freetype_DIR GDCM-ABI_DIR GLEW_DIR HYPRE_DIR IRON_DIR ITK_DIR ImageMagick_DIR)
list(APPEND ADVANCED_GUI_ENTRIES LIBCELLML_DIR LLVM_DIR LibCellML_DIR LibXml2_DIR METIS_DIR MUMPS_DIR NETGEN_DIR)
list(APPEND ADVANCED_GUI_ENTRIES OPTPP_DIR PARMETIS_DIR PASTIX_DIR PETSC_DIR PNG_DIR PTSCOTCH_DIR SCALAPACK_DIR)
list(APPEND ADVANCED_GUI_ENTRIES SUITESPARSE_DIR SUNDIALS_DIR SUPERLU_DIR SUPERLU_DIST_DIR TIFF_DIR ZINC_DIR ZLIB_DIR)
list(APPEND ADVANCED_GUI_ENTRIES QT_QMAKE_EXECUTABLE CMAKE_OSX_ARCHITECTURES CMAKE_OSX_DEPLOYMENT_TARGET CMAKE_OSX_SYSROOT)
list(APPEND ADVANCED_GUI_ENTRIES CMAKE_CODEBLOCKS_MAKE_ARGUMENT CMAKE_CODEBLOCKS_EXECUTABLE CMAKE_INSTALL_PREFIX)
mark_as_advanced(${ADVANCED_GUI_ENTRIES})
