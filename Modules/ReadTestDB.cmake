
macro(read_test_db_dir)
    # Read database of tests.
    file(GLOB test_files LIST_DIRECTORIES FALSE ${TEST_DB}/*.cmake)

    set(TEST_COUNT 0)
    foreach(test_file ${test_files})
        math(EXPR TEST_COUNT "${TEST_COUNT}+1")
        get_filename_component(test_file "${test_file}" NAME)
        add_functional_test(${TEST_DB}/${test_file})
    endforeach()
endmacro()

macro(read_test_db_file)
    set(TEST_COUNT 1)
    add_functional_test(${TEST_DB})
endmacro()

macro(add_functional_test TEST_DESCRIPTION_FILE)
    unset_test_variables()
    include(${TEST_DESCRIPTION_FILE})
    get_filename_component(TEST_NAME "${TEST_DESCRIPTION_FILE}" NAME_WE)
    set(TEST_${TEST_COUNT}_NAME ${TEST_NAME})
    set(TEST_${TEST_COUNT}_GIT_REPO ${TEST_GIT_REPO})
    set(TEST_${TEST_COUNT}_BRANCH ${TEST_BRANCH})

    foreach(_prefix TEST_ PYTEST_)
        set(${_prefix}${TEST_COUNT}_TARGETS ${${_prefix}TARGETS})
        set(${_prefix}${TEST_COUNT}_TARGETS_ARGS ${${_prefix}TARGETS_ARGS})
        set(${_prefix}${TEST_COUNT}_EXPECTED_RESULTS ${${_prefix}EXPECTED_RESULTS})
        if (DEFINED ${_prefix}TOLERANCE)
            set(${_prefix}${TEST_COUNT}_REL_TOLERANCE ${${_prefix}TOLERANCE})
	    set(${_prefix}REL_TOLERANCE ${${_prefix}TOLERANCE})
        else ()
            set(${_prefix}${TEST_COUNT}_REL_TOLERANCE 1e-14)
        endif ()
        if (DEFINED ${_prefix}REL_TOLERANCE)
            set(${_prefix}${TEST_COUNT}_REL_TOLERANCE ${${_prefix}REL_TOLERANCE})
        else ()
            set(${_prefix}${TEST_COUNT}_REL_TOLERANCE 1e-14)
        endif ()
        if (DEFINED ${_prefix}ABS_TOLERANCE)
            set(${_prefix}${TEST_COUNT}_ABS_TOLERANCE ${${_prefix}ABS_TOLERANCE})
        else ()
            set(${_prefix}${TEST_COUNT}_ABS_TOLERANCE 1.11e-15)
        endif ()
        if (DEFINED ${_prefix}MULTI_PROCESS)
            set(${_prefix}${TEST_COUNT}_MULTI_PROCESS ${${_prefix}MULTI_PROCESS})
            set(${_prefix}${TEST_COUNT}_NP ${${_prefix}NP})
        else ()
            set(${_prefix}${TEST_COUNT}_MULTI_PROCESS FALSE)
        endif ()
    endforeach()
endmacro()

macro(unset_test_variables)
    unset(TEST_NAME CACHE)
    unset(TEST_GIT_REPO CACHE)
    unset(TEST_BRANCH CACHE)

    foreach(_prefix TEST_ PYTEST_)
        unset(${_prefix}TARGETS CACHE)
        unset(${_prefix}TARGETS_ARGS CACHE)
        unset(${_prefix}EXPECTED_RESULTS CACHE)
        unset(${_prefix}TOLERANCE CACHE)
        unset(${_prefix}REL_TOLERANCE CACHE)
        unset(${_prefix}ABS_TOLERANCE CACHE)

        unset(${_prefix}MULTI_PROCESS CACHE)
        unset(${_prefix}NP CACHE)
    endforeach()

endmacro()
