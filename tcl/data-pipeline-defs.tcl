#
# /tcl/data-pipeline.tcl
#
# Data Pipeline - abstraction layer to dynamically generate
#  sql queries based on properly named html form elements.
#
# created by dvr 9/1/1999, to handle data processing for huge 
#  forms on guidestar.org
# rewritten by oumi 2/1/2000 as a module with added capabilities
#  including clob support
#
# $Id: data-pipeline-defs.tcl,v 3.1 2000/03/11 03:45:20 michael Exp $
#

util_report_library_entry

ad_proc dp_process {{-db "" -db_op "update_or_insert" -form_index "" -where_clause ""}} {Does database updates/inserts of all the fields passed from the previous form that start with dp$form_index.} {

    set release_db 0
    if { [empty_string_p $db] } {
	set release_db 1
	set db [ns_db gethandle subquery]
    }

    dp_read_form_variables
    # Like set_the_usual_for_variables, will return an error
    # if there is no input unless called with an argument of 0.
    #
    # Reads the form data in an ns_set called dp_form
 
    dp_read_checkboxes "_cv" "f"
    # Fills in unchecked boxes to update the data in the tables

    set error_list [dp_check_var_input $form_index]
    set num_errors [lindex $error_list 0]
    # iterates through all form variables and checks if the 
    # value matches the datatype (which is determined by looking
    # at the fourth part of the variable name)

    if { $num_errors > 0 } {
	ad_return_complaint $num_errors [lindex $error_list 1]
	return -code return
    }

    # ns_log Notice "\n\nform_index $form_index"

    set dp_sql_structs [dp_build_sql_structs $form_index]
    # create an ns_set where the key is the name of the table
    # and the value is a dp_sql_struct

    # Used to store results for each table
    set ora_results [ns_set create]

    # At this point, see what tables you have information for,
    # add any other variables that need to go into the table,
    # and do the updates

     if {![empty_string_p $dp_sql_structs]} {
	ns_db dml $db "begin transaction"
    
	set size [ns_set size $dp_sql_structs]
	for { set i 0 } { $i < $size } { incr i } {
	    set table_name [ns_set key $dp_sql_structs $i]
	    set sql_struct [ns_set value $dp_sql_structs $i]
	    set result [dp_sql_struct_execute \
		    $db $sql_struct $table_name $db_op $where_clause]
	    
	    ns_set put $ora_results $table_name $result
	}
    
	ns_db dml $db "end transaction"
    }

    if { $release_db } {
	ns_db releasehandle $db
    }

    return $ora_results
}

proc_doc dp_set_form_variables_after_query {{form_index ""} {table_name ""}} {Copy variables from the ns_set $selection into the ns_set $dp_form with the proper naming conventions for the data pipeline.  Caller must have $selection (just as for [set_variables_after_query])} {
    upvar selection selection
    upvar dp_form dp_form

    if {![info exists selection] || [empty_string_p $selection]} {
	return ""
    }

    if {![info exists dp_form] || [empty_string_p dp_form]} {
	set dp_form [ns_set new]
    }

    set form_size [ns_set size $selection]
    set form_ctr 0
    while {$form_ctr<$form_size} {
	ns_set put $dp_form\
            "dp$form_index.$table_name.[ns_set key $selection $form_ctr]"\
            [ns_set value $selection $form_ctr]
	incr form_ctr
    }

    return $dp_form
}

proc_doc dp_read_form_variables {{error_if_not_found_p 1}} {Reads the set from ns_getform info dp_form} {
    if { [ns_getform] == "" } {
        if $error_if_not_found_p {
            uplevel { 
    	        ns_returnerror 500 "Missing form data"
    	        return
            }
        } else {
            return
        }
    }
    uplevel {
        set dp_form [ns_getform]
    }	
}


proc_doc dp_var_value {varname} { get the value of $varname one way or another: 1) if dp_form exists, it uses those values to fill the form fields. 2) if dp_form is missing, it looks for dp_select, which should be an ns_set from a [ns_db select] } {
    upvar dp_form dp_form

    if [info exists dp_form] {
	if {[ns_set find $dp_form $varname] != -1} {
	    return [ns_set get $dp_form $varname]
	} else {
	    # strip off the data type and look for it again in dp_form.
	    set varname_no_data_type [join [lrange [split $varname .] 0 2] "."]
	    return [ns_set get $dp_form $varname_no_data_type]
	}
    } else {
        upvar dp_select dp_select
        if [info exists dp_select] {
            if [empty_string_p $dp_select] {
                return ""
            }
            set colname [lindex [split $varname .] 2]
            return [ns_set get $dp_select $colname]
        } else {
            # give up
	    return
        }
    }
}

proc_doc dp_export_form_value {varname} {Looks in dp_form and dp_select for the value for $varname and returns VALUE='$value' for use in an HTML form.} {

    upvar dp_form dp_form
    upvar dp_select dp_select

    set value [dp_var_value $varname]
    if ![empty_string_p $value] {
        return "VALUE='[philg_quote_double_quotes [dp_format_var_for_display $varname $value]]'"
    } else {
        return
    }
}

proc_doc dp_export_form_name_value {varname} {Looks in dp_form and dp_select for the value for $varname and returns NAME='$var' VALUE='$var' for use in an HTML form.} {

    upvar dp_form dp_form
    upvar dp_select dp_select

    set value [dp_var_value $varname]
    if ![empty_string_p $value] {
        return "NAME=\"$varname\" VALUE=\"[philg_quote_double_quotes [dp_format_var_for_display $varname $value]]\""
    } else {
        return "NAME=\"$varname\""
    }
}


proc_doc dp_select_yn {varname} {Create a pulldown menu with the options Yes and No for $varname. Will use dp_select to set the default value} {
    upvar dp_select dp_select
    return "<SELECT NAME=$varname>
[dp_optionlist $varname [list "" Yes No] [list "" Y N]]
</SELECT>"
}

proc_doc dp_optionlist {varname items values} {Similar to ad_generic_optionlist, except it uses dp_select to get the current value of varname} {
    upvar dp_select dp_select

    set default_value [dp_var_value $varname]

    ad_generic_optionlist $items $values $default_value
}



proc_doc dp_list_all_vars {} {Lists all the variables in dp_form} {
    upvar dp_form dp_form

    if [empty_string_p $dp_form] {
        return
    } else {
        set size [ns_set size $dp_form]
        for {set i 0} {$i < $size} {incr i} {
            lappend dp_vars [ns_set key $dp_form $i]
        }
        if [info exists dp_vars] {
            return $dp_packed_vars
        } else {
            return
        }
    }
}
  
proc_doc dp_list_packed_vars {{form_index ""} } {Lists all the variables in the dp_form that start with dp$form_index.*} {
    upvar dp_form dp_form

    if {![info exists dp_form] || [empty_string_p $dp_form]} {
        return
    } else {
        set size [ns_set size $dp_form]
        for {set i 0} {$i < $size} {incr i} {
            if [string match dp${form_index}.* \
		    [ns_set key $dp_form $i]] {
                lappend dp_packed_vars [ns_set key $dp_form $i]
            }
        }
        if [info exists dp_packed_vars] {
            return $dp_packed_vars
        } else {
            return
        }
    }
}

proc_doc dp_formvalue {name} {Returns the value that goes with key $name in dp_form} {
    upvar dp_form dp_form

    if [info exists dp_form] {
        return [ns_set get $dp_form $name]
    }
}


proc_doc dp_variable_type {varname} {Returns the datatype for $varname (really only reads the fourth part of th variable name)} {
    return [lindex [split $varname .] 3]
}

proc_doc dp_check_var {name value} {Checks the value of $name against the type of data that we expect to find. Returns null if the $name looks ok; returns an error otherwise.} {

    set type [dp_variable_type $name]
    switch -exact $type {
	phone {
	    ## It's hard to catch all the cases for phone numbers. We just make sure there 
	    ## are at least 10 characters
	    if { ![empty_string_p $value] && [string length $value] < 10 } {
		return "$value doesn't look like a valid phone number - please make sure that you entered in an area code"
	    }} 
	email {
	    ## Email address must be of the form yyy@xxx.zzz
	    if { ![empty_string_p $value] && ![philg_email_valid_p $value] } {
		return "The email address that you typed, $value, doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
             }}
        expr {
	    ## expressions are a potential security hole IF we allow people to
	    ## put in arbitrary strings. We limit expressions to 1 word (i.e. no
	    ## spaces).
	    set temp $value
	    regsub {^[ ]*} $temp "" temp
	    regsub {[ ]*$} $temp "" temp
            if { [regexp -- { } $temp] } {
                return "'$value' isn't a valid expression. Expressions can only be a single word."
	    }}
        year {
            if [regexp -- {[^0-9]} $value] {
                return "'$value' isn't a valid year"
            } elseif { [string length $value] != 4 } {
                return "A year must be a four-digit number (you entered '$value')"
            }}
        int {
            if [regexp -- {[^0-9]} $value] {
                return "'$value' isn't an integer"
            }}
        money {
	    regsub -all {,} $value {} value
            if {![empty_string_p $value] && [catch {expr $value * 2}]} {
                return "'$value' isn't a real number"
            }}
        date {
	    # We have to rearrange the ascii date format for the ns_buildsqldate function
	    set ymd [split $value {-}]
	    if { [catch { ns_buildsqldate [string trimleft [lindex $ymd 1] "0"] [lindex $ymd 2] [lindex $ymd 0] }] } {
		return "'$value' is not in the proper date format (YYYY-MM-DD)"

	}   }
	}
}


proc_doc dp_format_var_for_display {name value} {Formats the value of $name for the type of data that we are expecting. If there is no formatting to do, returns $value. Otherwise, returns a formatted $value.} {

    set type [dp_variable_type $name]
    switch -exact $type {
        money {
	    return [util_commify_number $value]
	}
    }
    return $value
}


proc_doc dp_check_var_input { {form_index ""} } {Takes the list of variables from dp_list_all_form_vars and runs each through dp_check_var. Returns a list of [error_count, error_message]. error_message is null if there are no errors.} {

    upvar dp_form dp_form

    set exception_count 0

    foreach var [dp_list_packed_vars $form_index] {
        set value [ns_set get $dp_form $var]
        set problem_with_input [dp_check_var $var $value]
        if ![empty_string_p $problem_with_input] {
            incr exception_count
            append exception_text "<LI>$problem_with_input";
        }
    }
    
    if { $exception_count > 0 } {
	return [list $exception_count $exception_text]
    }
    return [list 0 ""]

}


proc_doc dp_add_one_col_to_sql_struct {sql_struct col_name col_value {data_type text}} {Returns a little sql bit useful for update (e.g., last_name='O''Grady'), where the value is escaped based on the data type.} {

    dp_sql_struct_add_col_name $sql_struct $col_name

    switch -exact $data_type {
        year { 
	    dp_sql_struct_add_col_val $sql_struct "to_date('$col_value','YYYY')" 
	}
        money { 
            if [empty_string_p $col_value] {
                dp_sql_struct_add_col_val $sql_struct "null"
            } else {
		# take out any commas
		regsub -all {,} $col_value {} col_value
                dp_sql_struct_add_col_val $sql_struct "$col_value" 
	    }}
        int {
            if [empty_string_p $col_value] {
                dp_sql_struct_add_col_val $sql_struct "null"
            } else {
                dp_sql_struct_add_col_val $sql_struct "$col_value"
            }}
        expr {
            if [empty_string_p $col_value] {
                dp_sql_struct_add_col_val $sql_struct "null"
            } else {
                dp_sql_struct_add_col_val $sql_struct "$col_value"
            }}
	clob {
	    if {[empty_string_p $col_value]} {
		dp_sql_struct_add_col_val $sql_struct "null"
	    } elseif {[string length $col_value]<4000} {
		dp_sql_struct_add_col_val $sql_struct "'[DoubleApos $col_value]'"
	    } else {
		dp_sql_struct_add_col_val $sql_struct "empty_clob()"
		dp_sql_struct_set_tcl_proc $sql_struct "ns_ora clob_dml"
		dp_sql_struct_add_returning_col $sql_struct $col_name
		dp_sql_struct_add_tcl_extra_arg $sql_struct \{$col_value\}
	    }
	    
	}
	default { 
	    dp_sql_struct_add_col_val $sql_struct "'[DoubleApos $col_value]'" 
	}
     
    }
}

proc_doc dp_build_sql_structs {{form_index ""}} {
    Upvars to get the $dp_form ns_set, and builds a bunch of dp_sql_structs 
    that will perform the SQL necessary to process all the dp_form variables 
    prefixed by "dp$form_index".  The return value is an
    ns_set where key is table name and value is a dp_sql_struct.

    Arguments:
        form_index   - The only items in the $dp_form ns_set that get processed
                       are the ones whose keys are of the form 
                       "dp_form$form_index.*"
} {

    upvar dp_form dp_form

    set dp_sql_structs [ns_set new]
    foreach var [dp_list_packed_vars $form_index] {
        set varname_parts [split $var .]

        set table_name [lindex $varname_parts 1]
        set col_name   [lindex $varname_parts 2]
        set datatype   [lindex $varname_parts 3]

	if {![info exists table_sql_struct.$table_name]} {
	    set table_sql_struct.$table_name [dp_sql_struct_new]
	    ns_set put $dp_sql_structs $table_name \
		    [set table_sql_struct.$table_name]
	    set found_some_p 1
	}

	dp_add_one_col_to_sql_struct [set table_sql_struct.$table_name] $col_name [dp_formvalue $var] $datatype

    }

    if [info exists found_some_p] {
        return $dp_sql_structs
    } else {
        return
    }
}

proc_doc dp_sql_struct_execute {db sql_struct table_name db_op {where_clause ""}} {
    Given a dp_sql_struct and a database operation (db_opp), performs the
    SQL.  Currently, db_op is one of [ update | insert | update_or_insert ]
} {
    switch -exact $db_op {
	update {
	    return [dp_sql_struct_do_update \
		    $db $sql_struct $table_name $where_clause]
	}
	insert {
	    return [dp_sql_struct_do_insert \
		    $db $sql_struct $table_name]
	}
	update_or_insert {
	    return [dp_sql_struct_do_update_or_insert \
		    $db $sql_struct $table_name $where_clause]	    
	}
    }
}

# The next few procs make use of the dp_sql_struct abstract data type (defined 
# further below).  They take a dp_sql_struct and execute the proper SQL 
# statement represented by it.

# Given a dp_sql_struct, generate and perform the sql update
proc dp_sql_struct_do_update {db sql_struct table_name {where_clause ""}} {

    set full_where_clause ""
    if {![empty_string_p $where_clause]} {
	set full_where_clause "where $where_clause"
    }


    set col_names [dp_sql_struct_get_col_names $sql_struct]
    set col_vals [dp_sql_struct_get_col_vals $sql_struct]
    set name_equals_value_string ""
    set i 0
    foreach col $col_names {
	if {$i>0} {
	    append name_equals_value_string ",\n\t"
	}
	append name_equals_value_string "$col=[lindex $col_vals $i]"
	incr i
    }
    
    # WORKAROUND for oracle driver bug (see below). Because 
    # [ns_ora resultrows ...] won't work after [ns_ora clob_dml ...],
    # we pre-count how many rows match the where clause.  Then,
    # if the [ns_ora resultrows ...] call fails, we'll use the 
    # pre-counted $n_rows instead.  This may not be accurate if the
    # state of the database changes between the pre-count and update.
    set n_rows [database_to_tcl_string $db "
        select count(1) from $table_name $full_where_clause
    "]

    set sql [dp_sql_struct_make_sql_update_statement $sql_struct $table_name $where_clause]
    set tcl_proc [dp_sql_struct_get_tcl_proc $sql_struct]
    set extra_args [join [dp_sql_struct_get_tcl_extra_args $sql_struct] " "]

    eval "$tcl_proc \$db \$sql $extra_args"

# Oumi (Jan. 11, 2000) . . .
# THERE SEEMS TO BE A BUG IN THE ORACLE DRIVER.  ns_ora resultrows WON'T
# WORK IF THE LAST DML STATEMENT WAS VIA ns_ora clob_dml (or blob_dml).
# I think the problem is in line 2875 of ora8.c version 1.0.3 -- there is
# a flush_handle( dbh ) that always executes for clob_dml/blob_dml, 
# clearing out dbh->connection->statement

    if {[catch {
	set this_ora_result [ns_ora resultrows $db]
    } error_message]} {
	# error_message will say 'no active statement' after executing
	# a clob_dml.  We won't check the error_message though.  If
	# the [ns_ora resultrows $db] call failed, then just use the
	# pre-counted $n_rows.
	set this_ora_result $n_rows
    }

    return $this_ora_result
}

# Given a dp_sql_struct, try a SQL update.  If no rows are updated, then
# try an insert.
proc_doc dp_sql_struct_do_update_or_insert {db sql_struct table_name {where_clause ""}} {} {

    set ora_result [dp_sql_struct_do_update \
	    $db $sql_struct $table_name $where_clause]

    if {$ora_result == 0} {
	return [dp_sql_struct_do_insert $db $sql_struct $table_name]
    }
}

# Given a dp_sql_struct, perform a SQL insert
proc_doc dp_sql_struct_do_insert {db sql_struct table_name} {} {

    set sql [dp_sql_struct_make_sql_insert_statement $sql_struct $table_name]
    set tcl_proc [dp_sql_struct_get_tcl_proc $sql_struct]
    set extra_args [join [dp_sql_struct_get_tcl_extra_args $sql_struct] " "]

    eval "$tcl_proc \$db \$sql $extra_args"

    return
}

proc_doc dp_insert_checkbox {name values {on_value t} {hidden_field_name _cv} } "Inserts a checkbox and marks it if necessary (the value is on or Y). Also inserts a hidden field to record an uncheck in the box if necessary. Note that the name _cv stands for _check_vars, but is abbreviated so as to not hit the limit in the size of a get too easily." {
    if { ![empty_string_p $values] } {
	for {set i 0} {$i<[ns_set size $values]} {incr i} {
	    if {[ns_set key $values $i] == $name} {
		set value [philg_quote_double_quotes [ns_set value $values $i]]
		break;
	    } 
	}
    }

    set str "
<input type=hidden name=\"$hidden_field_name\" value=\"$name\">
<input type=checkbox name=\"$name\" value=$on_value"
   if { [info exists value] && $value == "$on_value" } {
       append str  " checked"
    }
    append str ">"
    return $str
}

proc_doc dp_read_checkboxes {{hidden_field_name _cv} {off_value N}} "Reads all checkboxes in the form and sets their value to either Y or N. Note that this function looks for a hidden field named hidden_field_name to get a list of all marked and unmarked checkboxes. This should be used in conjunction with dp_insert_checkbox that sets up the hidden fields automatically." {

    upvar dp_form dp_form

    set size [ns_set size $dp_form]
    set i 0

    while {$i<$size} {
	if { [ns_set key $dp_form $i] == $hidden_field_name} {
	    # list_of_vars will be created if it doesn't exist
	    lappend list_of_vars [ns_set value $dp_form $i]
	}
	incr i
    }

    if { ![info exists list_of_vars] || [empty_string_p $list_of_vars] } {
	return
    }

    foreach cb_var $list_of_vars {
	set val [ns_set get $dp_form $cb_var]
	if {[empty_string_p $val]} {
	    ns_set put $dp_form $cb_var $off_value
	}
    }
    return
}


##### All the "dp_sql_struct_*" procs define an abstract data type
##### This data structure is used for representing a Tcl statement that
##### executes a sql/dml statement.  The structure stores column names, 
#####
##### The structure is an ns_set that looks like:
#####     Key              Value
#####     ----------------------
#####     col_names      - a list of column names
#####     col_vals       - a list of column values.  Each val in col_vals
#####                      belongs to each column in col_names respectively
#####     returning_cols - list of column names for the returning clause
#####     tcl_proc       - tcl code to process sql; default is "ns_db dml"
#####     tcl_extra_args - list of extra args to tcl statement (used for clobs)
##### 
##### col_names, col_vals, and returning_cols are used informing the actual
##### sql statement.  The Tcl used to execute the sql is of the form:
#####     <tcl_proc> $db <sql statement> <tcl_extra_args>

# Create a dp_sql_struct
proc dp_sql_struct_new {} {
    set sql_struct [ns_set new]
    dp_sql_struct_set_tcl_proc $sql_struct "ns_db dml"
    return $sql_struct
}

# Retreive "col_vals" element of the dp_sql_struct
proc dp_sql_struct_get_col_vals {sql_struct} {
    return [ns_set get $sql_struct col_vals]
}

# Add a column value to the "col_vals" element of the dp_sql_struct
proc dp_sql_struct_add_col_val {sql_struct val} {
    set l [dp_sql_struct_get_col_vals $sql_struct]
    lappend l $val
    ns_set update $sql_struct col_vals $l
}

# Retreive "col_names" element of the dp_sql_struct
proc dp_sql_struct_get_col_names {sql_struct} {
    return [ns_set get $sql_struct col_names]
}

# Add a column name to the "col_names" element of the dp_sql_struct
proc dp_sql_struct_add_col_name {sql_struct col} {
    set l [dp_sql_struct_get_col_names $sql_struct]
    lappend l $col
    ns_set update $sql_struct col_names $l
}

# Retreive "returning_cols" element of the dp_sql_struct
proc dp_sql_struct_get_returning_cols {sql_struct} {
    return [ns_set get $sql_struct returning_cols]
}

# Add a column name to the "returning_cols" element of the dp_sql_struct
proc dp_sql_struct_add_returning_col {sql_struct col_name} {
    set l [dp_sql_struct_get_returning_cols $sql_struct]
    lappend l $col_name
    ns_set update $sql_struct returning_cols $l
}

# Retreive "tcl_proc" element of the dp_sql_struct
proc dp_sql_struct_get_tcl_proc {sql_struct} {
    return [ns_set get $sql_struct tcl_proc]
}

# Set the "tcl_proc" element of the dp_sql_struct
proc dp_sql_struct_set_tcl_proc {sql_struct tcl_proc} {
    ns_set update $sql_struct tcl_proc $tcl_proc
}

# Retreive "tcl_extra_args" element of the dp_sql_struct
proc dp_sql_struct_get_tcl_extra_args {sql_struct} {
    return [ns_set get $sql_struct tcl_extra_args]
}

# Add an argument to the "tcl_extra_args" element of the dp_sql_struct
proc dp_sql_struct_add_tcl_extra_arg {sql_struct tcl_extra_args} {
    set l [dp_sql_struct_get_tcl_extra_args $sql_struct]
    lappend l $tcl_extra_args
    ns_set update $sql_struct tcl_extra_args $l
}

# Given a dp_sql_struct, form a SQL "returning" clause (e.g.,
# "returning my_clob_1,my_clob_2 into :1,:2"
proc dp_sql_struct_make_returning_clause {sql_struct} {
    set returning_clause ""

    set returning_cols [dp_sql_struct_get_returning_cols $sql_struct]
    set i 0
    foreach col $returning_cols {
	incr i
	lappend bind_num_list ":$i"
    }
    if {$i > 0} {
	set returning_clause "returning [join $returning_cols ","] into [join $bind_num_list ","]"
    }

    return $returning_clause
}

# Given a dp_sql_struct, form a SQL update statement
proc dp_sql_struct_make_sql_update_statement {sql_struct table_name where_clause} {
    if {![empty_string_p $where_clause]} {
	set where_clause "where $where_clause"
    }
    set col_names [dp_sql_struct_get_col_names $sql_struct]
    set col_vals [dp_sql_struct_get_col_vals $sql_struct]
    set name_equals_value_string ""
    set i 0
    foreach col $col_names {
	if {$i>0} {
	    append name_equals_value_string ",\n\t"
	}
	append name_equals_value_string "$col=[lindex $col_vals $i]"
	incr i
    }


    return "
    update $table_name set
        $name_equals_value_string
    $where_clause [dp_sql_struct_make_returning_clause $sql_struct]"
}

# Given a dp_sql_struct, form a SQL insert statement
proc dp_sql_struct_make_sql_insert_statement {sql_struct table_name} {
    return "
    insert into $table_name (
        [join [dp_sql_struct_get_col_names $sql_struct] ","] 
    ) values (
        [join [dp_sql_struct_get_col_vals $sql_struct] ","] 
    ) [dp_sql_struct_make_returning_clause $sql_struct]
    "
}

####### END OF PROCS THAT DEFINE THE dp_sql_struct ABSTRACT DATA TYPE ########

util_report_successful_library_load
