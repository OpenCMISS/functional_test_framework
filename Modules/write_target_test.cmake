
function(write_test)
    write_target_test(${SETUP_CMAKELISTS_FILE} ${_current_name}
        ${_current_target} ${_current_root} ${_current_expected_results}
        ${_current_abs_tolerance} ${_current_rel_tolerance} ${_current_env} ${_current_args})
endfunction()
