ad_library {

    An API for managing database queries.

    @creation-date 15 Apr 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id 10-database-procs.tcl,v 1.4.2.11.2.39 2000/10/12 06:13:27 kevin Exp

}

ad_proc -public db_null {} {
    Represents the SQL keyword <code>null</code> for use in SQL DML statements.
} {
    # Oracle coerces the empty string into null, in DML.
    #
    return ""
}

ad_proc -public db_nullify_empty_string { string } {
    A convenience function that returns [db_null] if $string is the empty string.
} {
    if { [empty_string_p $string] } {
	return [db_null]
    } else {
	return $string
    }
}

proc_doc db_quote { string } { Quotes a string value to be placed in a SQL statement. } {
    regsub -all {'} "$string" {''} result
    return $result
}

proc_doc db_nextval { sequence } { Returns the next value for a sequence. Ultimately this will cache a block of sequence values to save hits to the database. } {
    return [db_string "nextval" "select $sequence.nextval from dual"]
}

 
proc_doc db_nth_pool_name { n } { 
    Returns the name of the pool used for the nth-nested selection (0-relative). 
} {
    set available_pools [nsv_get db_available_pools .]
    if { $n < [llength $available_pools] } {
	set pool [lindex $available_pools $n]
    } else {
	return -code error "Ran out of database pools ($available_pools)"
    }
    return $pool
}

#
# Initialize the list of available pools
#

global apm_first_time_loading_p
if { [info exist apm_first_time_loading_p] && $apm_first_time_loading_p } {
    set server_name [ns_info server]
    append config_path "ns/server/$server_name/acs/database"
    set the_set [ns_configsection $config_path]
    set pools [list]
    if {![empty_string_p $the_set]} {
	for {set i 0} {$i < [ns_set size $the_set]} {incr i} {
	    if { [ns_set key $the_set $i] ==  "AvailablePool" } {
		lappend pools [ns_set value $the_set $i]
	    }
	}
    }
    if { [llength $pools] == 0 } {
	set pools [ns_db pools]
    }
    ns_log Notice "Database API: The following pools are available: $pools"
    nsv_set db_available_pools . $pools
}

proc_doc db_with_handle { db code_block } {

Places a usable database handle in $db and executes $code_block.

} {
    upvar 1 $db dbh

    global ad_conn

    # Initialize bookkeeping variables.
    if { ![info exists ad_conn(db,handles)] } {
	set ad_conn(db,handles) [list]
    }
    if { ![info exists ad_conn(db,n_handles_used)] } {
	set ad_conn(db,n_handles_used) 0
    }
    if { $ad_conn(db,n_handles_used) >= [llength $ad_conn(db,handles)] } {
	set pool [db_nth_pool_name $ad_conn(db,n_handles_used)]
	set start_time [clock clicks]
	set errno [catch {
	    set db [ns_db gethandle $pool]
	} error]
	ad_call_proc_if_exists ds_collect_db_call $db gethandle "" $pool $start_time $errno $error
	lappend ad_conn(db,handles) $db
	if { $errno } {
	    global errorInfo errorCode
	    return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
	}
    }
    set my_dbh [lindex $ad_conn(db,handles) $ad_conn(db,n_handles_used)]
    set dbh $my_dbh
    set ad_conn(db,last_used) $my_dbh

    incr ad_conn(db,n_handles_used)
    set errno [catch { uplevel 1 $code_block } error]
    incr ad_conn(db,n_handles_used) -1

    # This may have changed while the code_block was being evaluated.
    set ad_conn(db,last_used) $my_dbh

    # Unset dbh, so any subsequence use of this variable will bomb.
    if { [info exists dbh] } {
	unset dbh
    }


    # If errno is 1, it's an error, so return errorCode and errorInfo;
    # if errno = 2, it's a return, so don't try to return errorCode/errorInfo
    # errno = 3 or 4 give undefined results
    
    if { $errno == 1 } {
	
	# A real error occurred
	global errorInfo errorCode
	return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
    }
    
    if { $errno == 2 } {
	
	# The code block called a "return", so pass the message through but don't try
	# to return errorCode or errorInfo since they may not exist
	
	return -code $errno $error
    }
}

proc_doc db_exec_plsql { statement_name sql args } {

    Executes a PL/SQL statement, returning the variable of bind variable <code>:1</code>.

} {
    ad_arg_parser { bind_output } $args
    if { [info exists bind_output] } {
	return -code error "the -bind_output switch is not currently supported"
    }

    db_with_handle db {
	# Right now, use :1 as the output value if it occurs in the statement,
	# or not otherwise.  However, we want to watch out for things like
	# 17:10:00.  Unfortunately, the regexp is still not perfect, since
	# "stuff : other stuff" will still screw things up.
	if { [regexp {[ \t]:1[ \t]} $sql] } {
	    return [db_exec exec_plsql_bind $db $statement_name $sql 1 ""]
	} else {
	    db_exec dml $db $statement_name $sql
	}
    }
}

proc_doc db_release_unused_handles {} {

Releases any database handles that are presently unused.

} {
    global ad_conn

    if { [info exists ad_conn(db,n_handles_used)] } {
	# Examine the elements at the end of ad_conn(db,handles), killing off
	# handles that are unused and not engaged in a transaction.

	set index_to_examine [expr { [llength $ad_conn(db,handles)] - 1 }]
	while { $index_to_examine >= $ad_conn(db,n_handles_used) } {
	    set db [lindex $ad_conn(db,handles) $index_to_examine]

	    # Stop now if the handle is part of a transaction.
	    if { [info exists ad_conn(db,transaction_level,$db)] && \
		    $ad_conn(db,transaction_level,$db) > 0 } {
		break
	    }

	    set start_time [clock clicks]
	    ns_db releasehandle $db
	    ad_call_proc_if_exists ds_collect_db_call $db releasehandle "" "" $start_time 0 ""
	    incr index_to_examine -1
	}
	set ad_conn(db,handles) [lrange $ad_conn(db,handles) 0 $index_to_examine]
    }
}

ad_proc -private db_getrow { db selection } {

    A helper procedure to perform an ns_db getrow, invoking developer support
    routines as necessary.

} {
    set start_time [clock clicks]
    set errno [catch { return [ns_db getrow $db $selection] } error]
    ad_call_proc_if_exists ds_collect_db_call $db getrow "" "" $start_time $errno $error
    if { $errno == 2 } {
	return $error
    }
    global errorInfo errorCode
    return -code $errno -errorinfo $errorInfo -errorcode $errorCode $error
}

ad_proc -private db_exec { type db statement_name sql args } {

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

} {
    set start_time [clock clicks]

    set errno [catch {
	upvar bind bind
	if { [info exists bind] && [llength $bind] != 0 } {
	    if { [llength $bind] == 1 } {
		return [eval [list ns_ora $type $db -bind $bind $sql] $args]
	    } else {
		set bind_vars [ns_set create]
		foreach { name value } $bind {
		    ns_set put $bind_vars $name $value
		}
		return [eval [list ns_ora $type $db -bind $bind_vars $sql] $args]
	    }
	} else {
	    return [uplevel 2 [list ns_ora $type $db $sql] $args]
	}
    } error]

    ad_call_proc_if_exists ds_collect_db_call $db $type $statement_name $sql $start_time $errno $error
    if { $errno == 2 } {
	return $error
    }

    global errorInfo errorCode
    return -code $errno -errorinfo $errorInfo -errorcode $errorCode $error
}

proc_doc db_string { statement_name sql args } {

    Returns the first column of the result of the SQL query $sql.
    If the query doesn't return a row, returns $default (or raises an error if no $default is provided).

} {
    ad_arg_parser { default bind } $args

    db_with_handle db {
	set selection [db_exec 0or1row $db $statement_name $sql]
    }

    if { [empty_string_p $selection] } {
	if { [info exists default] } {
	    return $default
	}
	return -code error "Selection did not return a value, and no default was provided"
    }
    return [ns_set value $selection 0]
}

proc_doc db_list { statement_name sql args } {

    Returns a list containing the first column of each row returned by the SQL query $sql.

} {
    ad_arg_parser { bind } $args

    # Can't use db_foreach here, since we need to use the ns_set directly.
    db_with_handle db {
	set selection [db_exec select $db $statement_name $sql]
	set result [list]
	while { [db_getrow $db $selection] } {
	    lappend result [ns_set value $selection 0]
	}
    }
    return $result
}

proc_doc db_list_of_lists { statement_name sql args } {

    Returns a list containing lists of the values in each column of each row returned by the SQL query $sql.

} {
    ad_arg_parser { bind } $args

    # Can't use db_foreach here, since we need to use the ns_set directly.
    db_with_handle db {
	set selection [db_exec select $db $statement_name $sql]

	set result [list]

	while { [db_getrow $db $selection] } {
	    set this_result [list]
	    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		lappend this_result [ns_set value $selection $i]
	    }
	    lappend result $this_result
	}
    }
    return $result
}

proc_doc db_foreach { statement_name sql args } {
    Usage: db_foreach statement_name sql [-bind ns_set | list of bind variables] code_block [if_no_rows if_no_rows_code_block]

Performs the SQL query $sql, executing code_block once for each row with variables set to column values.

<p>Example:

 <blockquote><pre>db_foreach greeble_query "select foo, bar from greeble" {
    ns_write "&lt;li&gt;foo=$foo; bar=$bar\n"
} if_no_rows {
    # This block is optional.
    ns_write "&lt;li&gt;No greebles!\n"
}</pre></blockquote>

} {
    ad_arg_parser { bind column_array column_set args } $args

    # Do some syntax checking.
    set arglength [llength $args]
    if { $arglength == 1 } {
	# Have only a code block.
	set code_block [lindex $args 0]
    } elseif { $arglength == 3 } {
	# Should have code block + if_no_rows + code block.
	if { ![string equal [lindex $args 1] "if_no_rows"] && ![string equal [lindex $args 1] "else"] } {
	    return -code error "Expected if_no_rows as second-to-last argument"
	}
	set code_block [lindex $args 0]
	set if_no_rows_code_block [lindex $args 2]
    } else {
	return -code error "Expected 1 or 3 arguments after switches"
    }

    if { [info exists column_array] && [info exists column_set] } {
	return -code error "Can't specify both column_array and column_set"
    }

    if { [info exists column_array] } {
	upvar 1 $column_array array_val
    }

    if { [info exists column_set] } {
	upvar 1 $column_set selection
    }

    db_with_handle db {
	set selection [db_exec select $db $statement_name $sql]

	set counter 0
	while { [db_getrow $db $selection] } {
	    incr counter
	    if { [info exists array_val] } {
		unset array_val
	    }
	    if { ![info exists column_set] } {
		for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		    if { [info exists column_array] } {
			set array_val([ns_set key $selection $i]) [ns_set value $selection $i]
		    } else {
			upvar 1 [ns_set key $selection $i] column_value
			set column_value [ns_set value $selection $i]
		    }
		}
	    }
	    set errno [catch { uplevel 1 $code_block } error]

	    # Handle or propagate the error. Can't use the usual "return -code $errno..." trick
	    # due to the db_with_handle wrapped around this loop, so propagate it explicitly.
	    switch $errno {
		0 {
		    # TCL_OK
		}
		1 {
		    # TCL_ERROR
		    global errorInfo errorCode
		    error $error $errorInfo $errorCode
		}
		2 {
		    # TCL_RETURN
		    error "Cannot return from inside a db_foreach loop"
		}
		3 {
		    # TCL_BREAK
		    ns_db flush $db
		    break
		}
		4 {
		    # TCL_CONTINUE - just ignore and continue looping.
		}
		default {
		    error "Unknown return code: $errno"
		}
	    }
	}
	# If the if_no_rows_code is defined, go ahead and run it.
	if { $counter == 0 && [info exists if_no_rows_code_block] } {
	    uplevel 1 $if_no_rows_code_block
	}
    }
}

proc_doc db_dml { statement_name sql args } {
    Do a DML statement.
} {
    ad_arg_parser { clobs blobs clob_files blob_files bind } $args

    # Only one of clobs, blobs, clob_files, and blob_files is allowed. Remember which one
    # (if any) is provided.
    set lob_argc 0
    set lob_argv [list]
    set command "dml"
    if { [info exists clobs] } {
	set command "clob_dml"
	set lob_argv $clobs
	incr lob_argc
    }
    if { [info exists blobs] } {
	set command "blob_dml"
	set lob_argv $blobs
	incr lob_argc
    }
    if { [info exists clob_files] } {
	set command "clob_dml_file"
	set lob_argv $clob_files
	incr lob_argc
    }
    if { [info exists blob_files] } {
	set command "blob_dml_file"
	set lob_argv $blob_files
	incr lob_argc
    }
    if { $lob_argc > 1 } {
	error "Only one of -clobs, -blobs, -clob_files, or -blob_files may be specified as an argument to db_dml"
    }
    db_with_handle db {
	if { $lob_argc == 1 } {
	    # Bind :1, :2, ..., :n as LOBs (where n = [llength $lob_argv])
	    set bind_vars [list]
	    for { set i 1 } { $i <= [llength $lob_argv] } { incr i } {
		lappend bind_vars $i
	    }
	    eval [list db_exec "${command}_bind" $db $statement_name $sql $bind_vars] $lob_argv
	} else {
	    eval [list db_exec $command $db $statement_name $sql] $lob_argv
	}
    }
}

proc_doc db_resultrows {} { Returns the number of rows affected by the last DML command. } {
    global ad_conn
    return [ns_ora resultrows $ad_conn(db,last_used)]
}

ad_proc db_0or1row { statement_name sql args } { 

Performs the SQL query $sql, setting variables to column values. Returns 1 if a row is returned, or 0 if no row is returned.

} {
    ad_arg_parser { bind column_array column_set } $args

    if { [info exists column_array] && [info exists column_set] } {
	return -code error "Can't specify both column_array and column_set"
    }

    if { [info exists column_array] } {
	upvar 1 $column_array array_val
	if { [info exists array_val] } {
	    unset array_val
	}
    }

    if { [info exists column_set] } {
	upvar 1 $column_set selection
    }

    db_with_handle db {
	set selection [db_exec 0or1row $db $statement_name $sql]
    }
    
    if { [empty_string_p $selection] } {
	return 0
    }

    if { [info exists column_array] } {
	for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
	    set array_val([ns_set key $selection $i]) [ns_set value $selection $i]
	}
    } elseif { ![info exists column_set] } {
	for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
	    upvar 1 [ns_set key $selection $i] value
	    set value [ns_set value $selection $i]
	}
    }

    return 1
}

ad_proc db_1row { args } {

Performs the SQL query $sql, setting variables to column values. Raises an error if no rows are returned.

} {
    if { ![uplevel db_0or1row $args] } {
	return -code error "Query did not return any rows."
    }
}

proc db_transaction_handle_error {db level errno errmsg} {
    switch $errno {
	0 {
	    # TCL_OK
	    return 0
	}

	1 {
	    # TCL_ERROR
	    if { ![string compare $errmsg "<<AD_SCRIPT_ABORT>>"] } {
		# We're aborting all processing.
		if { $level == 1 && [db_abort_transaction_p] } {
		    ns_db dml $db "abort transaction"
		    db_release_unused_handles
		}
		ad_script_abort
	    } else {
		# Normal error processing.
		return 1
	    }
	}

	2 {
	    # TCL_RETURN -- Calling TCL_RETURN within a db_transaction or an on_error block
	    # has unclear semantics.  We interpret this as an error.
	    if { $level == 1 && [db_abort_transaction_p]} {
		ns_db dml $db "abort transaction"
		db_release_unused_handles
	    }
	    error "Do not call 'return' in db_transaction or its on_error block.  
Please use 'ad_script_abort' to abort all processing or call return outside the transaction code."
	}
	default {
	    # TCL_BREAK, TCL_CONTINUE or unknown error code: Its an error.
	    return 1
	}
    }
}

ad_proc db_transaction { transaction_code args } {
    Executes transaction_code with transactional semantics.  This means that either all of the database commands
    within transaction_code are committed to the database or none of them are.  Multiple <code>db_transaction</code>s may be
    nested (end transaction is transparently ns_db dml'ed when the outermost transaction completes).<p>

    To handle errors, use <code>db_transaction {transaction_code} on_error {error_code}</code>.  Any error generated in 
    <code>transaction_code</code> will be caught automatically and process control will transfer to <code>error_code</code>
    with a variable <code>errmsg</code> set.  The error_code block can then clean up after the error, such as presenting a usable
    error message to the user.  Following the execution of <code>error_code</code> the transaction will be aborted.
    Alternatively, a command to continue the transaction <code>db_continue_transaction</code> can be issued.  This
    command will commit any successful database commands when the transaction completes, assuming no further errors are raised.  
    If you want to explicity abort the transaction, call <code>db_abort_transaction</code>
    from within the transaction_code block or the error_code block.<p>

    Example 1:<br>
    In this example, db_dml triggers an error, so control passes to the on_error block which prints a readable error.
    <pre>
    db_transaction {
	db_dml test "nonsense"
    } on_error {
	ad_return_complaint "The DML failed."
    }
    </pre>

    Example 2:<br>
    In this example, the second command, "nonsense" triggers an error.  There is no on_error block, so the
    transaction is immediately halted and aborted.
    <pre>
    db_transaction {
	db_dml test {insert into footest values(1)}
	nonsense
	db_dml test {insert into footest values(2)}
    } 
    </pre>

    Example 3:<br>
    In this example, all of the dml statements are executed and committed.  The call to db_abort_transaction
    signals that the transaction should be aborted which activates the higher level on_error block.  That code
    issues a db_continue_transaction which commits the transaction.  Had there not been an on_error block, none
    of the dml statements would have been committed.
    <pre>
    db_transaction {
	db_dml test {insert into footest values(1)}
	db_transaction {
	    db_dml test {insert into footest values(2) }
	    db_abort_transaction
	}
	db_dml test {insert into footest values(3) }
    } on_error {
	db_continue_transaction
    }
    </pre>
} {

    global ad_conn 
    
    set syn_err "db_transaction: Invalid arguments. Use db_transaction { code } \[on_error { error_code }\] "
    set arg_c [llength $args]
    
    if { $arg_c != 0 && $arg_c != 2 } {
	# Either this is a transaction with no error handling or there must be an on_error { code } block.
	error $syn_err
    }  elseif { $arg_c == 2 } {
	# We think they're specifying an on_error block
	if { [string compare [lindex $args 0] "on_error"] } {
	    # Unexpected: they put something besides on_error as a connector.
	    error $syn_err
	} else {
	    # Success! We got an on_error code block.
	    set on_error [lindex $args 1]
	}
    }
    # Make the error message and database handle available to the on_error block.
    upvar errmsg errmsg
    
    db_with_handle db {
	# Preserve the handle, since db_with_handle kills it after executing
	# this block.
	set dbh $db	
	# Remember that there's a transaction happening on this handle.
	if { ![info exists ad_conn(db,transaction_level,$dbh)] } {
	    set ad_conn(db,transaction_level,$dbh) 0
	}
	set level [incr ad_conn(db,transaction_level,$dbh)]
	if { $level == 1 } {
	    ns_db dml $dbh "begin transaction"
	}
    }
    # Execute the transaction code.
    set errno [catch {
	uplevel 1 $transaction_code 
    } errmsg]
    incr ad_conn(db,transaction_level,$dbh) -1
    set err_p [db_transaction_handle_error $dbh $level $errno $errmsg]
    if { $err_p } {
	# An error was triggered.
	db_abort_transaction
	if { [info exists on_error] && ![empty_string_p $on_error] } {
	    # An on_error block exists, so execute it.
	    set errno  [catch {
		uplevel 1 $on_error
	    } on_errmsg]
	    # Determine what do with the error.

	    set err_p [db_transaction_handle_error $dbh $level $errno $errmsg]
	    if { $err_p } {
		# An error was generated from the $on_error block.
		if { $level == 1} {
		    # We're at the top level, so we abort the transaction.
		    set ad_conn(db,db_abort_p,$dbh) 0
		    ns_db dml $dbh "abort transaction"
		} 
		# We throw this error because it was thrown from the error handling code that the programmer must fix.
		global errorInfo errorCode
		error $on_errmsg $errorInfo $errorCode
	    } else {
		# Good, no error thrown by the on_error block.
		if [db_abort_transaction_p] {
		    # This means we should abort the transaction.
		    # Use db_continue_transaction in the on_error block to avoid this.
		    if { $level == 1 } {
			set ad_conn(db,db_abort_p,$dbh) 0
			ns_db dml $dbh "abort transaction"
			# We still have the transaction generated error.  We don't want to throw it, so we log it.
			ns_log Error "Aborting transaction due to error:\n$errmsg" 
		    } else {
			# Propagate the error up to the next level.
			global errorInfo errorCode
			error $errmsg $errorInfo $errorCode
		    }
		} else {
		    # The on_error block has resolved the transaction error.  If we're at the top, commit and exit.
		    # Otherwise, we continue on through the lower transaction levels.
		    if { $level == 1} {
			ns_db dml $dbh "end transaction"
		    }
		}
	    }
	} else {
	    # There is no on_error block, yet there is an error, so we propagate it.
	    if { $level == 1 } {
		set ad_conn(db,db_abort_p,$dbh) 0
		ns_db dml $dbh "abort transaction"
		global errorInfo errorCode
		error "Transaction aborted: $errmsg" $errorInfo $errorCode
	    } else {
		db_abort_transaction
		global errorInfo errorCode
		error $errmsg $errorInfo $errorCode
	    }
	}
    } else {
	# There was no error from the transaction code.   
	if [db_abort_transaction_p] {
	    # The user requested the transaction be aborted.
	    if { $level == 1 } {
		set ad_conn(db,db_abort_p,$dbh) 0
		ns_db dml $dbh "abort transaction"
	    } 
	} elseif { $level == 1 } {
	    # Success!  No errors and no requested abort.  Commit.
	    ns_db dml $dbh "end transaction"
	}
    }
}

ad_proc db_abort_transaction {} { 
    
    Aborts a transaction. 
} {
    global ad_conn
    db_with_handle db {
	# We set the abort flag to true.
	set ad_conn(db,db_abort_p,$db) 1
    }
}


ad_proc db_abort_transaction_p {} { } {
     global ad_conn
    db_with_handle db {
	if { [info exists ad_conn(db,db_abort_p,$db)] } { 
	    return $ad_conn(db,db_abort_p,$db)
	} else {
	    # No abort flag registered, so we assume everything is ok.
	    return 0
	}
    }
}

ad_proc db_continue_transaction {} {
    
    If a transaction is set to be aborted, this procedure allows it to continue.
    Intended for use only within a db_transaction on_error code block.  
} {
    global ad_conn
    db_with_handle db {
	# The error has been handled, set the flag to false.
	set ad_conn(db,db_abort_p,$db) 0
    }
}

ad_proc db_write_clob { statement_name sql args } {
    ad_arg_parser { bind } $args

    db_with_handle db {
	db_exec write_clob $db $statement_name $sql
    }
}

ad_proc db_write_blob { statement_name sql args } {
    ad_arg_parser { bind } $args

    db_with_handle db { 
	db_exec write_blob $db $statement_name $sql
    }
}

ad_proc db_blob_get_file { statement_name sql args } {
    ad_arg_parser { bind } $args

    db_with_handle db {
	eval [list db_exec blob_get_file $db $statement_name $sql] $args
    }
}

# global ad_conn(db,handles) is a list of handles that have been allocated.
#
# global ad_conn(db,n_handles_used) is the number of handles in this list that are
# presently in use.
#
# E.g.:
#
#        db_foreach statement_name "select ..." {
#            # $ad_conn(db,handles) is "nsdb1"; $ad_conn(db,n_handles_used) is 1
#            db_foreach statement_name "select ..." {
#                # $ad_conn(db,handles) is "nsdb1 nsdb2"; $ad_conn(db,n_handles_used) is 2
#            }
#            # $ad_conn(db,handles) is "nsdb1 nsdb2"; $ad_conn(db,n_handles_used) is 1
#            db_release_unused_handles
#            # $ad_conn(db,handles) is "nsdb1"; $ad_conn(db,n_handles_used) is 1
#        }
#        # $ad_conn(db,handles) is "nsdb1"; $ad_conn(db,n_handles_used) is 0
#        db_release_unused_handles
#        # $ad_conn(db,handles) is ""; $ad_conn(db,n_handles_used) is 0
#
# The list of available pools are stored in the nsv db_available_pools(.) = { pool1 pool2 pool3 }
#
# This list is defined in the [ns/server/yourserver/acs/database] section using the key
# AvailablePool=foo (one line per pool).
#
# If none are specified, it defaults to all the pools available to AOLserver.
#
