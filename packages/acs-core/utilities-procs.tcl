# /packages/acs-core/utilties-procs.tcl

ad_library {

    Provides a variety of non-ACS-specific utilities

    @author Various [info@arsdigita.com]
    @date 13 April 2000
    @cvs-id utilities-procs.tcl,v 1.23.2.48 2001/01/12 21:07:36 khy Exp
}

# Let's define the nsv arrays out here, so we can call nsv_exists
# on their keys without checking to see if it already exists.
# we create the array by setting a bogus key.

proc proc_source_file_full_path {proc_name} {
    if ![nsv_exists proc_source_file $proc_name] {
	return ""
    } else {
	set tentative_path [nsv_get proc_source_file $proc_name]
	regsub -all {/\./} $tentative_path {/} result
	return $result
    }
}

proc_doc util_report_library_entry {{extra_message ""}} "Should be called at beginning of private Tcl library files so that it is easy to see in the error log whether or not private Tcl library files contain errors." {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { [string compare $extra_message ""] == 0 } {
	set message "Loading $scrubbed_path"
    } else {
	set message "Loading $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

# stuff to process the data that comes 
# back from the users

# if the form looked like
# <input type=text name=yow> and <input type=text name=bar> 
# then after you run this function you'll have Tcl vars 
# $foo and $bar set to whatever the user typed in the form

# this uses the initially nauseating but ultimately delicious
# Tcl system function "uplevel" that lets a subroutine bash
# the environment and local vars of its caller.  It ain't Common Lisp...

# This is an ad-hoc check to make sure users aren't trying to pass in
# "naughty" form variables in an effort to hack the database by passing
# in SQL. It is called in all instances where a Tcl variable
# is set from a form variable.

proc_doc check_for_form_variable_naughtiness { 
    name 
    value 
} {
    Checks the given variable for against known form variable exploits.
    If it finds anything objectionable, it throws an error.
} {
    # security patch contributed by michael@cleverly.com
    if { [string match "QQ*" $name] } {
        error "Form variables should never begin with QQ!"
    }

    # contributed by michael@cleverly.com
    if { [string match Vform_counter_i $name] } {
        error "Vform_counter_i not an allowed form variable"
    }

    # The statements below make ACS more secure, because it prevents
    # overwrite of variables from something like set_the_usual_form_variables
    # and it will be better if it was in the system. Yet, it is commented
    # out because it will cause an unstable release. To add this security
    # feature, we will need to go through all the code in the ACS and make
    # sure that the code doesn't try to overwrite intentionally and also
    # check to make sure that when tcl files are sourced from another proc,
    # the appropriate variables are unset.  If you want to install this
    # security feature, then you can look in the release notes for more info.
    # 
    # security patch contributed by michael@cleverly.com,
    # fixed by iwashima@arsdigita.com
    #
    # upvar 1 $name name_before
    # if { [info exists name_before] } {
    # The variable was set before the proc was called, and the
    # form attempts to overwrite it
    # error "Setting the variables from the form attempted to overwrite existing variable $name"
    # }
    
    # no naughtiness with uploaded files (discovered by ben@mit.edu)
    # patch by richardl@arsdigita.com, with no thanks to
    # jsc@arsdigita.com.
    if { [string match "*tmpfile" $name] } {
        set tmp_filename [ns_queryget $name]

        # ensure no .. in the path
        ns_normalizepath $tmp_filename

        set passed_check_p 0

        # check to make sure path is to an authorized directory
        set tmpdir_list [ad_parameter_all_values_as_list TmpDir]
        if [empty_string_p $tmpdir_list] {
            set tmpdir_list [list "/var/tmp" "/tmp"]
        }

        foreach tmpdir $tmpdir_list {
            if { [string match "$tmpdir*" $tmp_filename] } {
                set passed_check_p 1
                break
            }
        }

        if { !$passed_check_p } {
            error "You specified a path to a file that is not allowed on the system!"
        }
    
    }

    # integrates with the ad_set_typed_form_variable_filter system
    # written by dvr@arsdigita.com

    # see if this is one of the typed variables
    global ad_typed_form_variables    

    if [info exists ad_typed_form_variables] { 

        foreach typed_var_spec $ad_typed_form_variables {
            set typed_var_name [lindex $typed_var_spec 0]
        
            if ![string match $typed_var_name $name] {
                # no match. Go to the next variable in the list
                continue
            }
        
            # the variable matched the pattern
            set typed_var_type [lindex $typed_var_spec 1]
        
            if [string match "" $typed_var_type] {
                # if they don't specify a type, the default is 'integer'
                set typed_var_type integer
            }

            set variable_safe_p [ad_var_type_check_${typed_var_type}_p $value]
        
            if !$variable_safe_p {
                ns_returnerror 500 "variable $name failed '$typed_var_type' type check"
                ns_log Error "[ns_conn url] called with \$$name = $value"
                error "variable $name failed '$typed_var_type' type check"
            }

            # we've found the first element in the list that matches,
            # and we don't want to check against any others
            break
        }
    }
}


proc set_form_variables {{error_if_not_found_p 1}} {
    if { $error_if_not_found_p == 1} {
	uplevel { if { [ns_getform] == "" } {
	    ns_returnerror 500 "Missing form data"
	    return
	}
       }
     } else {
	 uplevel { if { [ns_getform] == "" } {
	     # we're not supposed to barf at the user but we want to return
	     # from this subroutine anyway because otherwise we'd get an error
	     return
	 }
     }
  }

    # at this point we know that the form is legal
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set $Vname $Vvalue
	    incr Vform_counter_i
	}
    }
}

proc DoubleApos {string} {
    regsub -all ' "$string" '' result
    return $result
}

# if the user types "O'Malley" and you try to insert that into an SQL
# database, you will lose big time because the single quote is magic
# in SQL and the insert has to look like 'O''Malley'.  This function
# also trims white space off the ends of the user-typed data.

# if the form looked like
# <input type=text name=yow> and <input type=text name=bar> 
# then after you run this function you'll have Tcl vars 
# $QQfoo and $QQbar set to whatever the user typed in the form
# plus an extra single quote in front of the user's single quotes
# and maybe some missing white space

proc set_form_variables_string_trim_DoubleAposQQ {} {
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	if {$Vform == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set QQ$Vname [DoubleApos [string trim $Vvalue]]
	    incr Vform_counter_i
	}
    }
}

# this one does both the regular and the QQ

proc set_the_usual_form_variables {{error_if_not_found_p 1}} {
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

    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set QQ$Vname [DoubleApos [string trim $Vvalue]]
	    set $Vname $Vvalue
	    incr Vform_counter_i
	}
    }
}

proc set_form_variables_string_trim_DoubleApos {} {
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	if {$Vform == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set $Vname [DoubleApos [string trim $Vvalue]]
	    incr Vform_counter_i
	}
    }
}

proc set_form_variables_string_trim {} {
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	if {$Vform == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set $Vname [string trim $Vvalue]
	    incr Vform_counter_i
	}
    }
}

# debugging kludges

proc NsSettoTclString {set_id} {
    set result ""
    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	append result "[ns_set key $set_id $i] : [ns_set value $set_id $i]\n"
    }
    return $result
}

proc get_referrer {} {
    return [ns_set get [ns_conn headers] Referer]
}

proc post_args_to_query_string {} {
    set arg_form [ns_getform]
    if {$arg_form!=""} {
	set form_counter_i 0
	while {$form_counter_i<[ns_set size $arg_form]} {
	    append query_return "[ns_set key $arg_form $form_counter_i]=[ns_urlencode [ns_set value $arg_form $form_counter_i]]&"
	    incr form_counter_i
	}
	set query_return [string trim $query_return &]
    }
}    

proc get_referrer_and_query_string {} {
    if {[ns_conn method]!="GET"} {
	set query_return [post_args_to_query_string]
	return "[get_referrer]?${query_return}"
    } else {
	return [get_referrer]
    }
}

# a philg hack for getting all the values from a set of checkboxes
# returns 0 if none are checked, a Tcl list with the values otherwise 
# terence change: specify default return if none checked
proc_doc util_GetCheckboxValues {form checkbox_name {default_return 0}} "For getting all the boxes from a set of checkboxes in a form.  This procedure takes the complete ns_conn form and returns a list of checkbox values.  It returns 0 if none are found (or some other default return value if specified)." {

    set i 0
    set size [ns_set size $form]

    while {$i<$size} {

        if { [ns_set key $form $i] == $checkbox_name} {

            set value [ns_set value $form $i]
            check_for_form_variable_naughtiness $checkbox_name $value

            # LIST_TO_RETURN will be created if it doesn't exist
            lappend list_to_return $value
        }
        incr i
    }

    #if no list, you can specify a default return
    #default default is 0

    if { [info exists list_to_return] } { return $list_to_return } else {return $default_return}
}

# a legacy name that is deprecated
proc nmc_GetCheckboxValues {form checkbox_name {default_return 0}} {
    return [util_GetCheckboxValues $form $checkbox_name $default_return]
}

##
#  Database-related code
##

ad_proc ad_dbclick_check_dml { 
    {
	-bind  ""
    }
    statement_name table_name id_column_name generated_id return_url insert_dml 
} {
    This proc is used for pages using double click protection. table_name
    is table_name for which we are checking whether the double click
    occured. id_column_name is the name of the id table
    column. generated_id is the generated id, which is supposed to have
    been generated on the previous page. return_url is url to which this 
    procedure will return redirect in the case of successful insertion in
    the database. insert_sql is the sql insert statement. if data is ok
    this procedure will insert data into the database in a double click
    safe manner and will returnredirect to the page specified by
    return_url. if database insert fails, this procedure will return a
    sensible error message to the user.
} {
    if [catch {
	if { ![empty_string_p $bind] } {
	    	db_dml $statement_name $insert_dml -bind $bind
	} else {
	    db_dml $statement_name $insert_dml 
	}
    } errmsg] {
	# Oracle choked on the insert
	
	# detect double click
        if {
	    [db_0or1row double_click_check "
		
		select 1 as one
		from $table_name
		where $id_column_name = :generated_id
		
	    " -bind [ad_tcl_vars_to_ns_set generated_id]]
	} {
	    ad_returnredirect $return_url
	    return
	}
	
	ns_log Error "[info script] choked. Oracle returned error:  $errmsg"

	ad_return_error "Error in insert" "
	We were unable to do your insert in the database. 
	Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
	return
    }

    ad_returnredirect $return_url
    return
}

proc nmc_IllustraDatetoPrettyDate {sql_date} {

    regexp {(.*)-(.*)-(.*)$} $sql_date match year month day

    set allthemonths {January February March April May June July August September October November December}

    # we have to trim the leading zero because Tcl has such a 
    # brain damaged model of numbers and decided that "09-1"
    # was "8.0"

    set trimmed_month [string trimleft $month 0]
    set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

    return "$pretty_month $day, $year"

}

proc util_IllustraDatetoPrettyDate {sql_date} {

    regexp {(.*)-(.*)-(.*)$} $sql_date match year month day

    set allthemonths {January February March April May June July August September October November December}

    # we have to trim the leading zero because Tcl has such a 
    # brain damaged model of numbers and decided that "09-1"
    # was "8.0"

    set trimmed_month [string trimleft $month 0]
    set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

    return "$pretty_month $day, $year"

}

# this is the preferred one to use

proc_doc util_AnsiDatetoPrettyDate {sql_date} "Converts 1998-09-05 to September 5, 1998" {
    if ![regexp {(.*)-(.*)-(.*)$} $sql_date match year month day] {
	return ""
    } else {
	set allthemonths {January February March April May June July August September October November December}

	# we have to trim the leading zero because Tcl has such a 
	# brain damaged model of numbers and decided that "09-1"
	# was "8.0"

	set trimmed_month [string trimleft $month 0]
	set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

	set trimmed_day [string trimleft $day 0]

	return "$pretty_month $trimmed_day, $year"
    }
}

# from the new-utilities.tcl file

proc remove_nulls_from_ns_set {old_set_id} {

    set new_set_id [ns_set new "no_nulls$old_set_id"]

    for {set i 0} {$i<[ns_set size $old_set_id]} {incr i} {
	if { [ns_set value $old_set_id $i] != "" } {

	    ns_set put $new_set_id [ns_set key $old_set_id $i] [ns_set value $old_set_id $i]

	}

    }

    return $new_set_id

}

proc merge_form_with_ns_set {form set_id} {

    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
    }

    return $form

}

ad_proc -public merge_form_with_query {
    {
	-bind {}
    }
    form statement_name sql_qry 
} {
    Merges a form with a query string.
    @param form the form to be stuffed.
    @param statement_name An identifier for the sql_qry to be executed.
    @param sql_qry The sql that must be executed.
    @param bind A ns_set stuffed with bind variables for the sql_qry.
} {
    set set_id [ns_set create]

    ns_log Notice "statement_name = $statement_name"
    ns_log Notice "sql_qry = $sql_qry"
    ns_log Notice "set_id = $set_id"

    db_0or1row $statement_name $sql_qry -bind $bind -column_set set_id
    
    if { $set_id != "" } {
	
	for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	    set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
	}
	
    }
    return $form    
}


proc_doc bt_mergepiece {htmlpiece values} "" {
    # HTMLPIECE is a form usually; VALUES is an ns_set

    # NEW VERSION DONE BY BEN ADIDA (ben@mit.edu)
    # Last modification (ben@mit.edu) on Jan ?? 1998
    # added support for dates in the date_entry_widget.
    #
    # modification (ben@mit.edu) on Jan 12th, 1998
    # when the val of an option tag is "", things screwed up
    # FIXED.
    #
    # This used to count the number of vars already introduced
    # in the form (see remaining num_vars statements), so as 
    # to end early. However, for some unknown reason, this cut off a number 
    # of forms. So now, this processes every tag in the HTML form.

    set newhtml ""
    
    set html_piece_ben $htmlpiece

    set num_vars 0

    for {set i 0} {$i<[ns_set size $values]} {incr i} {
	if {[ns_set key $values $i] != ""} {
	    set database_values([ns_set key $values $i]) [util_quote_double_quotes [ns_set value $values $i]]
	    incr num_vars
	} 
    }

    set vv {[Vv][Aa][Ll][Uu][Ee]}     ; # Sorta obvious
    set nn {[Nn][Aa][Mm][Ee]}         ; # This is too
    set qq {"([^"]*)"}                ; # Matches what's in quotes
    set pp {([^ ]*)}                  ; # Matches a word (mind yer pp and qq)
#"
    set slist {}
    
    set count 0

    while {1} {

	incr count
	set start_point [string first < $html_piece_ben]
	if {$start_point==-1} {
	    append newhtml $html_piece_ben
	    break;
	}
	if {$start_point>0} {
	    append newhtml [string range $html_piece_ben 0 [expr $start_point - 1]]
	}
	set end_point [string first > $html_piece_ben]
	if {$end_point==-1} break
	incr start_point
	incr end_point -1
	set tag [string range $html_piece_ben $start_point $end_point]
	incr end_point 2
	set html_piece_ben [string range $html_piece_ben $end_point end]
	set CAPTAG [string toupper $tag]

	set first_white [string first " " $CAPTAG]
	set first_word [string range $CAPTAG 0 [expr $first_white - 1]]
	
	switch -regexp $CAPTAG {
	    
	    {^INPUT} {
		if {[regexp {TYPE[ ]*=[ ]*("IMAGE"|"SUBMIT"|"RESET"|IMAGE|SUBMIT|RESET)} $CAPTAG]} {
		    
		    ###
		    #   Ignore these
		    ###
		    
		    append newhtml <$tag>
		    
		} elseif {[regexp {TYPE[ ]*=[ ]*("CHECKBOX"|CHECKBOX)} $CAPTAG]} {
		    # philg and jesse added optional whitespace 8/9/97
		    ## If it's a CHECKBOX, we cycle through
		    #  all the possible ns_set pair to see if it should
		    ## end up CHECKED or not.
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}
		    
		    if {[regexp "$vv=$qq" $tag m val]} {}\
			    elseif {[regexp "$vv=$pp" $tag m val]} {}\
			    else {set val ""}
		    
		    regsub -all {[Cc][Hh][Ee][Cc][Kk][Ee][Dd]} $tag {} tag
		    
		    # support for multiple check boxes provided by michael cleverly
		    if {[info exists database_values($nam)]} {
			if {[ns_set unique $values $nam]} {
			    if {$database_values($nam) == $val} {
				append tag " checked"
				incr num_vars -1
			    }
			} else {
			    for {set i [ns_set find $values $nam]} {$i < [ns_set size $values]} {incr i} {
				if {[ns_set key $values $i] == $nam && [util_quote_double_quotes [ns_set value $values $i]] == $val} {
				    append tag " checked"
				    incr num_vars -1
				    break
				}
			    }
			}
		    }

		    append newhtml <$tag>
		    
		} elseif {[regexp {TYPE[ ]*=[ ]*("RADIO"|RADIO)} $CAPTAG]} {
		    
		    ## If it's a RADIO, we remove all the other
		    #  choices beyond the first to keep from having
		    ## more than one CHECKED
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}
		    
		    if {[regexp "$vv=$qq" $tag m val]} {}\
			    elseif {[regexp "$vv=$pp" $tag m val]} {}\
			    else {set val ""}
		    
		    #Modified by Ben Adida (ben@mit.edu) so that
		    # the checked tags are eliminated only if something
		    # is in the database. 
		    
		    if {[info exists database_values($nam)]} {
			regsub -all {[Cc][Hh][Ee][Cc][Kk][Ee][Dd]} $tag {} tag
			if {$database_values($nam)==$val} {
			    append tag " checked"
			    incr num_vars -1
			}
		    }
		    
		    append newhtml <$tag>
		    
		} else {
		    
		    ## If it's an INPUT TYPE that hasn't been covered
		    #  (text, password, hidden, other (defaults to text))
		    ## then we add/replace the VALUE tag
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}

		    set nam [ns_urldecode $nam]

		    if {[info exists database_values($nam)]} {
			regsub -all "$vv=$qq" $tag {} tag
			regsub -all "$vv=$pp" $tag {} tag
			append tag " value=\"$database_values($nam)\""
			incr num_vars -1
		    } else {
			if {[regexp {([^.]*).([^ ]*)} $tag all nam type]} {
			    set typ ""
			    if {[string match $type "day"]} {
				set typ "day"
			    }
			    if {[string match $type "year"]} {
				set typ "year"
			    }
			    if {$typ != ""} {
				if {[info exists database_values($nam)]} {
				    regsub -all "$vv=$qq" $tag {} tag
				    regsub -all "$vv=$pp" $tag {} tag
				    append tag " value=\"[ns_parsesqldate $typ $database_values($nam)]\""
				}
			    }
			    #append tag "><nam=$nam type=$type typ=$typ" 
			}
		    }
		    append newhtml <$tag>
		}
	    }
	    
	    {^TEXTAREA} {
		
		###
		#   Fill in the middle of this tag
		###
		
		if {[regexp "$nn=$qq" $tag m nam]} {}\
			elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			else {set nam ""}
		
		if {[info exists database_values($nam)]} {
		    while {![regexp {^<( *)/[Tt][Ee][Xx][Tt][Aa][Rr][Ee][Aa]} $html_piece_ben]} {
			regexp {^.[^<]*(.*)} $html_piece_ben m html_piece_ben
		    }
		    append newhtml <$tag>$database_values($nam)
		    incr num_vars -1
		} else {
		    append newhtml <$tag>
		}
	    }
	    
	    {^SELECT} {
		
		###
		#   Set the snam flag, and perhaps smul, too
		###
		
		set smul [regexp "MULTIPLE" $CAPTAG]
		
		set sflg 1
		
		set select_date 0
		
		if {[regexp "$nn=$qq" $tag m snam]} {}\
			elseif {[regexp "$nn=$pp" $tag m snam]} {}\
			else {set snam ""}

		# In case it's a date
		if {[regexp {([^.]*).month} $snam all real_snam]} {
		    if {[info exists database_values($real_snam)]} {
			set snam $real_snam
			set select_date 1
		    }
		}
		
		lappend slist $snam
		
		append newhtml <$tag>
	    }
	    
	    {^OPTION} {
		
		###
		#   Find the value for this
		###
		
		if {$snam != ""} {
		    
		    if {[lsearch -exact $slist $snam] != -1} {regsub -all {[Ss][Ee][Ll][Ee][Cc][Tt][Ee][Dd]} $tag {} tag}
		    
		    if {[regexp "$vv *= *$qq" $tag m opt]} {}\
			    elseif {[regexp "$vv *= *$pp" $tag m opt]} {}\
			    else {
			if {[info exists opt]} {
			    unset opt
		    }   }
		    # at this point we've figured out what the default from the form was
		    # and put it in $opt (if the default was spec'd inside the OPTION tag
		    # just in case it wasn't, we're going to look for it in the 
		    # human-readable part
		    regexp {^([^<]*)(.*)} $html_piece_ben m txt html_piece_ben
		    if {![info exists opt]} {
			set val [string trim $txt]
		    } else {
			set val $opt
		    }
		    
		    if {[info exists database_values($snam)]} {
			# If we're dealing with a date
			if {$select_date == 1} {
			    set db_val [ns_parsesqldate month $database_values($snam)]
			} else {
			    set db_val $database_values($snam)
			}

			if {
			    ($smul || $sflg) &&
			    [string match $db_val $val]
			} then {
			    append tag " selected"
			    incr num_vars -1
			    set sflg 0
			}
		    }
		}
		append newhtml <$tag>$txt
	    }
	    
	    {^/SELECT} {
		    
		###
		#   Do we need to add to the end?
		###
		
		set txt ""
		
		if {$snam != ""} {
		    if {[info exists database_values($snam)] && $sflg} {
			append txt "<option selected>$database_values($snam)"
			incr num_vars -1
			if {!$smul} {set snam ""}
		    }
		}
		
		append newhtml $txt<$tag>
	    }
	    
	    {default} {
		append newhtml <$tag>
	    }
	}
	
    }
    return $newhtml
}

proc util_prepare_update {table_name primary_key_name primary_key_value form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    set column_list [db_columns $table_name]
    set bind_vars [ad_tcl_list_list_to_ns_set [list [list $primary_key_name $primary_key_value]]]

    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	if { ($form_var_name != $primary_key_name) && ([lsearch $column_list $form_var_name] != -1) } {

	    ad_tcl_list_list_to_ns_set -set_id $bind_vars [list [list $form_var_name $value]]
	    lappend the_sets "$form_var_name = :$form_var_name"

	}

	incr form_counter_i
    }

    return [list "update $table_name\nset [join $the_sets ",\n"] \n where $primary_key_name = :$primary_key_name" $bind_vars]
   
}

proc util_prepare_update_multi_key {table_name primary_key_name_list primary_key_value_list form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    set bind_vars [ns_set create]

    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	if { [lsearch -exact $primary_key_name_list $form_var_name] == -1 } {

	    # this is not one of the keys
	    ad_tcl_list_list_to_ns_set -set_id $bind_vars [list [list $form_var_name $value]]
	    lappend the_sets "$form_var_name = :$form_var_name"

	}

	incr form_counter_i
    }

    for {set i 0} {$i<[llength $primary_key_name_list]} {incr i} {

	set this_key_name [lindex $primary_key_name_list $i]
	set this_key_value [lindex $primary_key_value_list $i]

	ad_tcl_list_list_to_ns_set -set_id $bind_vars [list [list $this_key_name $this_key_value]]
	lappend key_eqns "$this_key_name = :$this_key_name"

    }

    return [list "update $table_name\nset [join $the_sets ",\n"] \n where [join $key_eqns " AND "]" $bind_vars]
}

proc util_prepare_insert {table_name form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    set bind_vars [ns_set create]

    while { $form_counter_i < $form_size } {

 	ns_set update $bind_vars [ns_set key $form $form_counter_i] [string trim [ns_set value $form $form_counter_i]]
 	incr form_counter_i

    }

    return [list "insert into $table_name\n([join [ad_ns_set_keys $bind_vars] ", "])\n values ([join [ad_ns_set_keys -colon $bind_vars] ", "])" $bind_vars]
}

proc util_PrettySex {m_or_f { default "default" }} {
    if { $m_or_f == "M" || $m_or_f == "m" } {
	return "Male"
    } elseif { $m_or_f == "F" || $m_or_f == "f" } {
	return "Female"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Unknown (\"$m_or_f\")"
	} else {
	    return $default
	}
    }
}

proc util_PrettySexManWoman {m_or_f { default "default"} } {
    if { $m_or_f == "M" || $m_or_f == "m" } {
	return "Man"
    } elseif { $m_or_f == "F" || $m_or_f == "f" } {
	return "Woman"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Person of Unknown Sex"
	} else {
	    return $default
	}
    }
}

proc util_PrettyBoolean {t_or_f { default  "default" } } {
    if { $t_or_f == "t" || $t_or_f == "T" } {
	return "Yes"
    } elseif { $t_or_f == "f" || $t_or_f == "F" } {
	return "No"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Unknown (\"$t_or_f\")"
	} else {
	    return $default
	}
    }
}

proc_doc util_PrettyTclBoolean {zero_or_one} "Turns a 1 (or anything else that makes a Tcl IF happy) into Yes; anything else into No" {
    if $zero_or_one {
	return "Yes"
    } else {
	return "No"
    }
}

# Pre-declare the cache arrays used in util_memoize.
nsv_set util_memoize_cache_value . ""
nsv_set util_memoize_cache_timestamp . ""

proc_doc util_memoize {tcl_statement {oldest_acceptable_value_in_seconds ""}} "Returns the result of evaluating the Tcl statement argument and then remembers that value in a cache; the memory persists for the specified number of seconds (or until the server is restarted if the second argument is not supplied) or until someone calls util_memoize_flush with the same Tcl statement.  Note that this procedure should be used with care because it calls the eval built-in procedure (and therefore an unscrupulous user could  " {

    # we look up the statement in the cache to see if it has already
    # been eval'd.  The statement itself is the key

    if { ![nsv_exists util_memoize_cache_value $tcl_statement] || ( ![empty_string_p $oldest_acceptable_value_in_seconds] && ([expr [nsv_get util_memoize_cache_timestamp $tcl_statement] + $oldest_acceptable_value_in_seconds] < [ns_time]) )} {

	# not in the cache already OR the caller spec'd an expiration
	# time and our cached value is too old

	set statement_value [eval $tcl_statement]
	nsv_set util_memoize_cache_value $tcl_statement $statement_value
	# store the time in seconds since 1970
	nsv_set util_memoize_cache_timestamp $tcl_statement [ns_time]
    }

    return [nsv_get util_memoize_cache_value $tcl_statement]
}

proc_doc util_memoize_seed {tcl_statement value {oldest_acceptable_value_in_seconds ""}} "Seeds the memoize catch with a particular value. If clustering is enabled, flushes cached values from peers in the cluster." {
    if { [llength [info procs server_cluster_httpget_from_peers]] == 1 } {
	server_cluster_httpget_from_peers "/SYSTEM/flush-memoized-statement.tcl?statement=[ns_urlencode $tcl_statement]"
    }
    nsv_set util_memoize_cache_value $tcl_statement $value
    # store the time in seconds since 1970
    nsv_set util_memoize_cache_timestamp $tcl_statement [ns_time]
}

# flush the cache

proc_doc util_memoize_flush_local {tcl_statement} "Flush the cached value only on the local server. In general you will want to use util_memoize_flush instead of this!" {
    if [nsv_exists util_memoize_cache_value $tcl_statement] {
	nsv_unset util_memoize_cache_value $tcl_statement
    }
    if [nsv_exists util_memoize_cache_timestamp $tcl_statement] {
	nsv_unset util_memoize_cache_timestamp $tcl_statement
    }
}

proc_doc util_memoize_flush {tcl_statement} "Flush the cached value (established with util_memoize associated with the argument). If clustering is enabled, flushes cached values from peers in the cluster." {
    if { [llength [info procs server_cluster_httpget_from_peers]] == 1 } {
	server_cluster_httpget_from_peers "/SYSTEM/flush-memoized-statement.tcl?statement=[ns_urlencode $tcl_statement]"
    }
    util_memoize_flush_local $tcl_statement
}

proc_doc util_memoize_value_cached_p {tcl_statement {oldest_acceptable_value_in_seconds ""}} "Returns 1 if there is a cached value for this Tcl expression.  If a second argument is supplied, only returns 1 if the cached value isn't too old." {

    # we look up the statement in the cache to see if it has already
    # been eval'd.  The statement itself is the key

    if { ![nsv_exists util_memoize_cache_value $tcl_statement] || ( ![empty_string_p $oldest_acceptable_value_in_seconds] && ([expr [nsv_get util_memoize_cache_timestamp $tcl_statement] + $oldest_acceptable_value_in_seconds] < [ns_time]) )} {
	return 0
    } else {
	return 1
    }    
}

proc current_year {} {
    util_memoize "current_year_internal"
}

proc current_year_internal {} {
    return [db_string current_year "select to_char(sysdate,'YYYY') from dual"]
}

proc philg_server_default_pool {} {
    set server_name [ns_info server]
    append config_path "ns\\server\\" $server_name "\\db"
    set default_pool [ns_config $config_path DefaultPool]
    return $default_pool
}

# this is typically called like this...
# philg_urldecode_form_variable [ns_getform]
# and it is called for effect, not value
# we use it if we've urlencoded something for a hidden
# variable (e.g., to escape the string quotes) in a form

proc philg_urldecode_form_variable {form variable_name} {
    set old_value [ns_set get $form $variable_name]
    set new_value [ns_urldecode $old_value]
    # one has to delete the old value first, otherwise
    # you just get two values for the same key in the ns_set
    ns_set delkey $form $variable_name
    ns_set put $form $variable_name $new_value
}

proc util_GetUserAgentHeader {} {
    set header [ns_conn headers]

    # note that this MUST be case-insensitive search (iget)
    # due to a NaviServer bug -- philg 2/1/96

    set userag [ns_set iget $header "USER-AGENT"]
    return $userag
}

proc msie_p {} {
    return [regexp -nocase {msie} [util_GetUserAgentHeader]]
}

proc submit_button_if_msie_p {} {
    if { [msie_p] } {
	return "<input type=submit>"
    } else {
	return ""
    }
}

proc randomInit {seed} {
    nsv_set rand ia 9301
    nsv_set rand ic 49297
    nsv_set rand im 233280
    nsv_set rand seed $seed
}

# initialize the random number generator

randomInit [ns_time]

proc random {} {
    nsv_set rand seed [expr ([nsv_get rand seed] * [nsv_get rand ia] + [nsv_get rand ic]) % [nsv_get rand im]]
    return [expr [nsv_get rand seed]/double([nsv_get rand im])]
}

proc randomRange {range} {
    return [expr int([random] * $range)]
}

proc capitalize {word} {
    if {$word != ""} {
	set newword ""
	if [regexp {[^ ]* [^ ]*} $word] {
	    set words [split $word]
	    foreach part $words {
		set newword "$newword [capitalize $part]"
	    }
	} else {
	    regexp {^(.)(.*)$} $word match firstchar rest
	    set newword [string toupper $firstchar]$rest
	}
	return [string trim $newword]
    }
    return $word
}

proc html_select_options {options {select_option ""}} {
    #this is html to be placed into a select tag
    set select_options ""
    foreach option $options {
	if { [lsearch $select_option $option] != -1 } {
	    append select_options "<option selected>$option\n"
	} else {
	    append select_options "<option>$option\n"
	}
    }
    return $select_options
}

ad_proc -public db_html_select_options { 
    { -bind "" }
    { -select_option "" }
    stmt_name
    sql
} {

    Generate html option tags for an html selection widget. If select_option
    is passed, this option will be marked as selected.

    @author yon [yon@arsdigita.com]

} {

    set select_options ""

    if { ![empty_string_p $bind] } {
	set options [db_list $stmt_name $sql -bind $bind]
    } else {
	set options [db_list $stmt_name $sql]
    }

    foreach option $options {
	if { [string compare $option $select_option] == 0 } {
	    append select_options "<option selected>$option\n"
	} else {
	    append select_options "<option>$option\n"
	}
    }
    return $select_options

}

ad_proc -public db_html_select_value_options {
    { -bind "" }
    { -select_option "" }
    { -value_index 0 }
    { -option_index 1 }
    stmt_name
    sql
} {

    Generate html option tags with values for an html selection widget. if
    select_option is passed and there exists a value for it in the values
    list, this option will be marked as selected. 

    @author yon [yon@arsdigita.com]

} {
    set select_options ""

    if { ![empty_string_p $bind] } {
	set options [db_list_of_lists $stmt_name $sql -bind $bind]
    } else {
	set options [uplevel [list db_list_of_lists $stmt_name $sql]]
    }

    foreach option $options {
	if { [string compare $select_option [lindex $option $value_index]] == 0 } {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\" selected>[lindex $option $option_index]\n"
	} else {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\">[lindex $option $option_index]\n"
	}
    }
    return $select_options

}

proc html_select_value_options {options {select_option ""} {value_index 0} {option_index 1}} {
    #this is html to be placed into a select tag
    #when value!=option, set the index of the return list
    #from the db query. selected option must match value

    set select_options ""
    foreach option $options {
	if { [string compare $select_option [lindex $option $value_index]] == 0 } {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\" selected>[lindex $option $option_index]\n"
	} else {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\">[lindex $option $option_index]\n"
	}
    }
    return $select_options
}

# produces a safe-for-browsers hidden variable, i.e., one where
# " has been replaced by &quot; 

ad_proc ad_hidden_input {name value} {
    Returns a safe-for-browsers hidden variable, i.e. one where " has
    been replaced by &quote 
} {
    #"
    return "<input type=hidden name=\"$name\" value=\"[util_quote_double_quotes $value]\">"
}

# this REGEXP was very kindly contributed by Jeff Friedl, author of 
# _Mastering Regular Expressions_ (O'Reilly 1997)
# (lars 31/Mar/00): Changed to also filter out attempts to write html tags in an email address

ad_proc ad_email_valid_p {query_email} {
    Returns 1 if an email address has more or less the correct form
} {
    # Original regexp
    # return [regexp "^\[^@\t ]+@\[^@.\t]+(\\.\[^@.\n ]+)+$" $query_email]

    return [regexp "^\[^@<>\"\t ]+@\[^@<>\".\t]+(\\.\[^@<>\".\n ]+)+$" $query_email]
}

ad_proc ad_url_valid_p {query_url} {
    Returns 1 if a URL has more or less the correct form.
} {
    return [regexp {https?://.+} $query_url]
}

ad_proc ad_date_valid_p {query_date} {
    Returns 1 if the given string has the right format for a date
} {
    return [regexp {[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]} $query_date]
}

# -----------------------------------------------------------------------------
# Deprecated versions of the above procs
# -----------------------------------------------------------------------------

ad_proc -deprecated philg_date_valid_p {query_date} {
    See ad_date_valid_p
} {
    return [ad_date_valid_p $query_date]
}

ad_proc -deprecated philg_hidden_input {name value} {
    See ad_hidden_input
} {
    return [ad_hidden_input $name $value]
}


ad_proc -deprecated philg_url_valid_p {query_url} {
    See ad_url_valid_p
} {
    return [ad_url_valid_p $query_url]
}

ad_proc -deprecated philg_email_valid_p {query_email} {
    See ad_email_valid_p
} {
    return [ad_email_valid_p $query_email]
}

# -----------------------------------------------------------------------------

# Return a string of hidden input fields for a form to pass along any
# of the parameters in args if they exist in the current environment.
#  -- jsc@arsdigita.com

# usage:  [export_form_vars foo bar baz]

ad_proc export_form_vars { 
    -sign:boolean
    args 
} {
    Exports a number of variables as hidden input fields in a form.
    Specify a list of variable names. The proc will reach up in the caller's name space
    to grab the value of the variables. Variables that are not defined are silently ignored.
    You can append :multiple to the name of a variable. In this case, the value will be treated as a list,
    and each of the elements output separately.

    <p>

    Example usage: <code>[export_form_vars -sign foo bar:multiple baz]</code>

    @param sign If this flag is set, all the variables output will be
    signed using <a
    href="/api-doc/proc-view?proc=ad_sign"><code>ad_sign</code></a>. These variables should then be
    verified using the :verify flag to <a
    href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>,
    which in turn uses <a
    href="/api-doc/proc-view?proc=ad_verify_signature"><code>ad_verify_signature</code></a>. This
    ensures that the value hasn't been tampered with at the user's end.

} { 
    set hidden ""
    foreach var_spec $args {
	set var_spec_pieces [split $var_spec ":"]
	set var [lindex $var_spec_pieces 0]
	set type [lindex $var_spec_pieces 1]
	upvar 1 $var value
	if { [info exists value] } {
	    switch $type {
		multiple {
		    foreach item $value {
			append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $var]\" value=\"[ad_quotehtml $item]\">\n"
		    }
		}
		default {
		    append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $var]\" value=\"[ad_quotehtml $value]\">\n"
		}
	    }
	    if { $sign_p } {
		append hidden "<input type=\"hidden\" name=\"[ad_quotehtml "$var:sig"]\" value=\"[ad_quotehtml [ad_sign $value]]\">\n"
	    }
	}
    }
    return $hidden
}


proc export_entire_form {} {
    set hidden ""
    set the_form [ns_getform]
    for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
	set varname [ns_set key $the_form $i]
	set varvalue [ns_set value $the_form $i]
	append hidden "<input type=hidden name=\"$varname\" value=\"[util_quote_double_quotes $varvalue]\">\n"
    }
    return $hidden
}

proc_doc export_ns_set_vars {{format "url"} {exclusion_list ""}  {setid ""}} "Returns all the params in an ns_set with the exception of those in exclusion_list. If no setid is provide, ns_getform is used. If format = url, a url parameter string will be returned. If format = form, a block of hidden form fragments will be returned."  {

    if [empty_string_p $setid] {
	set setid [ns_getform]
    }

    set return_list [list]
    if ![empty_string_p $setid] {
        set set_size [ns_set size $setid]
        set set_counter_i 0
        while { $set_counter_i<$set_size } {
            set name [ns_set key $setid $set_counter_i]
            set value [ns_set value $setid $set_counter_i]
            if {[lsearch $exclusion_list $name] == -1 && ![empty_string_p $name]} {
                if {$format == "url"} {
                    lappend return_list "$name=[ns_urlencode $value]"
                } else {
                    lappend return_list " name=$name value=\"[util_quote_double_quotes $value]\""
                }
            }
            incr set_counter_i
        }
    }
    if {$format == "url"} {
        return [join $return_list "&"]
    } else {
        return "<input type=hidden [join $return_list ">\n <input type=hidden "] >"
    }
}

ad_proc export_url_vars {
    -sign:boolean
    args 
} {

    Returns a string of key=value pairs suitable for inclusion in a
    URL; you can pass it any number of variables as arguments.  If any are
    defined in the caller's environment, they are included.  See also
    export_entire_form_as_url_vars.

    <p>

    Instead of naming a variable you can also say name=value. Note that the value here is not 
    the name of a variable but the literal value you want to export e.g.,
    <code>export_url_vars [ns_urlencode foo]=[ns_urlencode $the_value]</code>.

    <p>

    For normal variables, you can say <code>export_url_vars foo:multiple</code>. In this case, 
    the value of foo will be treated as a Tcl list, and each value will be output separately e.g., 
    foo=item0&foo=item1&foo=item2...

    <p>

    You cannot combine the foo=bar syntax with the foo:multiple syntax. Why? Because there's no way we can distinguish 
    between the :multiple being part of the value of foo or being a flag intended for export_url_vars.

    @param sign If this flag is set, all the variables output will be
    signed using <a
    href="/api-doc/proc-view?proc=ad_sign"><code>ad_sign</code></a>. These variables should then be
    verified using the :verify flag to <a
    href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>,
    which in turn uses <a
    href="/api-doc/proc-view?proc=ad_verify_signature"><code>ad_verify_signature</code></a>. This
    ensures that the value hasn't been tampered with at the user's end.
} { 
    set params {} 
    foreach var_spec $args { 
	if { [string first "=" $var_spec] != -1 } {
	    # There shouldn't be more than one equal sign, since the value should already be url-encoded.
	    set var_spec_pieces [split $var_spec "="]
	    set var [lindex $var_spec_pieces 0]
	    set value [lindex $var_spec_pieces 1]
	    lappend params "$var=$value"
	    if { $sign_p } {
		lappend params "[ns_urlencode [ns_urldecode $var]:sig]=[ns_urlencode [ad_sign [ns_urldecode $value]]]"
	    }
	} else {
	    set var_spec_pieces [split $var_spec ":"]
	    set var [lindex $var_spec_pieces 0]
	    set type [lindex $var_spec_pieces 1]
	    
	    upvar 1 $var upvar_value
	    if { [info exists upvar_value] } {
		switch $type {
		    multiple {
			foreach item $upvar_value {
			    lappend params "[ns_urlencode $var]=[ns_urlencode $item]"
			}
		    }
		    default {
			lappend params "[ns_urlencode $var]=[ns_urlencode $upvar_value]" 
		    }
		}
		if { $sign_p } {
		    lappend params "[ns_urlencode "$var:sig"]=[ns_urlencode [ad_sign $upvar_value]]"
		}
	    }
	}
    }
    
  return [join $params "&"]
}

 
proc_doc export_entire_form_as_url_vars {{vars_to_passthrough ""}} "Returns a URL parameter string of name-value pairs of all the form parameters passed to this page. If vars_to_passthrough is given, it should be a list of parameter names that will be the only ones passed through." {
    set params [list]
    set the_form [ns_getform]
    for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
	set varname [ns_set key $the_form $i]
	set varvalue [ns_set value $the_form $i]
	if { $vars_to_passthrough == "" || ([lsearch -exact $vars_to_passthrough $varname] != -1) } {
	    lappend params "$varname=[ns_urlencode $varvalue]" 
	}
    }
    return [join $params "&"]
}

# we use this to shut off spam scheduling and such 
# it asks the question "is this just a development server"?

# we write DevelopmentServer=1 into the server portion of the .ini file

# [ns/server/philg]
# DevelopmentServer=1

proc philg_development_p {} {
    set config_param [ns_config "ns/server/[ns_info server]" DevelopmentServer]
    if { $config_param == 1 } {
	return 1
    } else {
	return 0
    }
}

proc philg_keywords_match {keywords string_to_search} {
    # turn keywords into space-separated things
    # replace one or more commads with a space
    regsub -all {,+} $keywords " " keywords_no_commas
    set keyword_list [split $keywords_no_commas " "]
    set found_p 0
    foreach word $keyword_list {
	# turns out that "" is never found in a search, so we
	# don't really have to special case $word == ""
	if { $word != "" && [string first [string toupper $word] [string toupper $string_to_search]] != -1 } {
	    # found it!
	    set found_p 1
	}
    }
    return $found_p
}

proc_doc philg_keywords_score {keywords string_to_search} "Takes space-separated keywords and returns 0 if none are found or a count of how many matched.  If a keyword occurs twice then it is weighted 2." {
    # turn keywords into space-separated things
    # replace one or more commads with a space
    regsub -all {,+} $keywords " " keywords_no_commas
    set keyword_list [split $keywords_no_commas " "]
    set score 0
    foreach word $keyword_list {
	# turns out that "" is never found in a search, so we
	# don't really have to special case $word == ""
	if { $word != "" && [string first [string toupper $word] [string toupper $string_to_search]] != -1 } {
	    # found at least one!
	    if { [string first [string toupper $word] [string toupper $string_to_search]] == [string last [string toupper $word] [string toupper $string_to_search]] } {
		# only one occurrence
		incr score
	    } else {
		# more than one, count as 2 (like AltaVista)
		incr score 2
	    }
	}
    }
    return $score
}

# usage: 
#   suppose the variable is called "expiration_date"
#   put "[philg_dateentrywidget expiration_date]" in your form
#     and it will expand into lots of weird generated var names
#   put ns_dbformvalue [ns_getform] expiration_date date expiration_date
#     and whatever the user typed will be set in $expiration_date

proc philg_dateentrywidget {column {default_date "1940-11-03"}} {
    ns_share NS

    set output "<SELECT name=$column.month>\n"
    for {set i 0} {$i < 12} {incr i} {
	append output "<OPTION> [lindex $NS(months) $i]\n"
    }

    append output \
"</SELECT>&nbsp;<INPUT NAME=$column.day\
TYPE=text SIZE=3 MAXLENGTH=2>&nbsp;<INPUT NAME=$column.year\
TYPE=text SIZE=5 MAXLENGTH=4>"

    return [ns_dbformvalueput $output $column date $default_date]
}

proc philg_dateentrywidget_default_to_today {column} {
    set today [lindex [split [ns_localsqltimestamp] " "] 0]
    return [philg_dateentrywidget $column $today]
}

# Perform the dml statements in sql_list in a transaction.
# Aborts the transaction and returns an error message if
# an error occurred for any of the statements, otherwise
# returns null string. -jsc
proc do_dml_transactions {dml_stmt_list} {
    db_transaction {
	foreach dml_stmt $dml_stmt_list {
	    if { [catch {db_dml $dml_stmt} errmsg] } {
		db_abort_transaction
		return $errmsg
	    }
	}
    }
    return ""
}

# Perform body within a database transaction.
# Execute on_error if there was some error caught
# within body, with errmsg bound.
# This procedure will clobber errmsg in the caller.
# -jsc
proc with_transaction {body on_error} {
    upvar errmsg errmsg
    global errorInfo errorCode
    if { [catch {db_transaction { uplevel $body }} errmsg] } {
        db_abort_transaction
        set code [catch {uplevel $on_error} string]
        # Return out of the caller appropriately.
        if { $code == 1 } {
            return -code error -errorinfo $errorInfo -errorcode $errorCode $string
        } elseif { $code == 2 } {
            return -code return $string
        } elseif { $code == 3 } {
            return -code break
	} elseif { $code == 4 } {
	    return -code continue
        } elseif { $code > 4 } {
            return -code $code $string
        }
    }        
}

proc with_catch {error_var body on_error} { 
    upvar 1 $error_var $error_var 
    global errorInfo errorCode 
    if [catch { uplevel $body } $error_var] { 
        set code [catch {uplevel $on_error} string] 
        # Return out of the caller appropriately. 
        if { $code == 1 } { 
            return -code error -errorinfo $errorInfo -errorcode $errorCode $string 
        } elseif { $code == 2 } { 
            return -code return $string 
        } elseif { $code == 3 } { 
            return -code break
	} elseif { $code == 4 } {
	    return -code continue
        } elseif { $code > 4 } { 
            return -code $code $string 
        } 
    }         
} 

proc_doc string_contains_p {small_string big_string} {Returns 1 if the BIG_STRING contains the SMALL_STRING, 0 otherwise; syntactic sugar for string first != -1} {
    if { [string first $small_string $big_string] == -1 } {
	return 0
    } else {
	return 1
    }
}

proc remove_whitespace {input_string} {
    if [regsub -all "\[\015\012\t \]" $input_string "" output_string] {
	return $output_string 
    } else {
	return $input_string
    }
}

proc util_just_the_digits {input_string} {
    if [regsub -all {[^0-9]} $input_string "" output_string] {
	return $output_string 
    } else {
	return $input_string
    }
}

# sort of the opposite (for phone numbers, takes
# 6172538574 and turns it into "(617) 253-8574")

proc philg_format_phone_number {just_the_digits} {
    if { [string length $just_the_digits] != 10 } {
	return $just_the_digits
    } else {
	return "([string range $just_the_digits 0 2]) [string range $just_the_digits 3 5]-[string range $just_the_digits 6 9]"
    }
}

# putting commas into numbers (thank you, Michael Bryzek)

proc_doc util_commify_number { num } {Returns the number with commas inserted where appropriate. Number can be positive or negative and can have a decimal point. e.g. -1465.98 => -1,465.98} {
    while { 1 } {
	# Regular Expression taken from Mastering Regular Expressions (Jeff Friedl)
	# matches optional leading negative sign plus any
	# other 3 digits, starting from end
	if { ![regsub -- {^(-?[0-9]+)([0-9][0-9][0-9])} $num {\1,\2} num] } {
	    break
	}
    }
    return $num
}

# for limiting a string to 4000 characters because the Oracle SQL
# parser is so stupid and can only handle a string literal that long

proc util_limit_to_4000_chars {input_string} {
    return [string range $input_string 0 3999]
}

proc leap_year_p {year} {
    expr ( $year % 4 == 0 ) && ( ( $year % 100 != 0 ) || ( $year % 400 == 0 ) )
}

# Helper function, acts like perl shift:
# Return value of first element and remove it from the list.
proc shift {list_name} {
    upvar 1 $list_name list_to_shift
    set first_arg_p 1
    set first_arg ""
    set rest ""

    foreach element $list_to_shift {
        if { $first_arg_p } {
            set first_arg $element
            set first_arg_p 0
        } else {
            lappend rest $element
        }
    }
    set list_to_shift $rest
    return $first_arg
}

# Helper function: If its argument does not start with "{", surround
# it with a pair of braces.
proc format_as_list {some_list} {
    if { [string index $some_list 0] == "\{" } {
        return $some_list
    } else {
        return "{$some_list}"
    }
}

proc_doc util_search_list_of_lists {list_of_lists query_string {sublist_element_pos 0}} "Returns position of sublist that contains QUERY_STRING at SUBLIST_ELEMENT_POS." {
    set sublist_index 0
    foreach sublist $list_of_lists {
	set comparison_element [lindex $sublist $sublist_element_pos]
	if { [string compare $query_string $comparison_element] == 0 } {
	    return $sublist_index
	}
	incr sublist_index
    }
    # didn't find it
    return -1
}

# --- network stuff 

proc_doc util_get_http_status {url {use_get_p 1} {timeout 30}} "Returns the HTTP status code, e.g., 200 for a normal response or 500 for an error, of a URL.  By default this uses the GET method instead of HEAD since not all servers will respond properly to a HEAD request even when the URL is perfectly valid.  Note that this means AOLserver may be sucking down a lot of bits that it doesn't need." { 
    if $use_get_p {
	set http [ns_httpopen GET $url "" $timeout] 
    } else {
	set http [ns_httpopen HEAD $url "" $timeout] 
    }
    # philg changed these to close BOTH rfd and wfd
    set rfd [lindex $http 0] 
    set wfd [lindex $http 1] 
    close $rfd
    close $wfd
    set headers [lindex $http 2] 
    set response [ns_set name $headers] 
    set status [lindex $response 1] 
    ns_set free $headers
    return $status
}

proc_doc util_link_responding_p {url {list_of_bad_codes "404"}} "Returns 1 if the URL is responding (generally we think that anything other than 404 (not found) is okay)." {
    if [catch { set status [util_get_http_status $url] } errmsg] {
	# got an error; definitely not valid
	return 0
    } else {
	# we got the page but it might have been a 404 or something
	if { [lsearch $list_of_bad_codes $status] != -1 } {
	    return 0
	} else {
	    return 1
	}
    }
}

# system by Tracy Adams (teadams@arsdigita.com) to permit AOLserver to POST 
# to another Web server; sort of like ns_httpget

proc_doc util_httpopen {method url {rqset ""} {timeout 30} {http_referer ""}} {
    Like ns_httpopen but works for POST as well; called by util_httppost 
} {
    
	if ![string match http://* $url] {
		return -code error "Invalid url \"$url\":  _httpopen only supports HTTP"
	}
	set url [split $url /]
	set hp [split [lindex $url 2] :]
	set host [lindex $hp 0]
	set port [lindex $hp 1]
	if [string match $port ""] {set port 80}
	set uri /[join [lrange $url 3 end] /]
	set fds [ns_sockopen -nonblock $host $port]
	set rfd [lindex $fds 0]
	set wfd [lindex $fds 1]
	if [catch {
		_ns_http_puts $timeout $wfd "$method $uri HTTP/1.0\r"
		if {$rqset != ""} {
			for {set i 0} {$i < [ns_set size $rqset]} {incr i} {
				_ns_http_puts $timeout $wfd \
					"[ns_set key $rqset $i]: [ns_set value $rqset $i]\r"
			}
		} else {
			_ns_http_puts $timeout $wfd \
				"Accept: */*\r"

		    	_ns_http_puts $timeout $wfd "User-Agent: Mozilla/1.01 \[en\] (Win95; I)\r"    
		    	_ns_http_puts $timeout $wfd "Referer: $http_referer \r"    
	}

    } errMsg] {
		global errorInfo
		#close $wfd
		#close $rfd
		if [info exists rpset] {ns_set free $rpset}
		return -1
	}
	return [list $rfd $wfd ""]
    
}

# httppost; give it a URL and a string with formvars, and it 
# returns the page as a Tcl string
# formvars are the posted variables in the following form: 
#        arg1=value1&arg2=value2

# in the event of an error or timeout, -1 is returned

proc_doc util_httppost {
    url formvars {timeout 30} {depth 0} {http_referer ""}
} {
    Returns the result of POSTing to another Web server or -1 if there is an error or timeout.  formvars should be in the form \"arg1=value1&arg2=value2\"
} {

    if [catch {
	if {[incr depth] > 10} {
	    return -code error "util_httppost:  Recursive redirection:  $url"
	}
	set req_hdrs [ns_set create]

	ns_set put $req_hdrs "Content-type" "application/x-www-form-urlencoded"
	ns_set put $req_hdrs "Content-length" [string length $formvars]
	set http [ns_httpopen POST $url $req_hdrs $timeout $formvars]
	set rfd [lindex $http 0]
	set wfd [lindex $http 1]
	set rpset [lindex $http 2]

	#headers necesary for a post and the form variables

	flush $wfd
	close $wfd

	set headers $rpset
	set response [ns_set name $headers]
	set status [lindex $response 1]
	if {$status == 302} {
	    set location [ns_set iget $headers location]
	    if {$location != ""} {
		ns_set free $headers
		close $rfd
		return [util_httppost $location $formvars $timeout $depth $http_referer]
	    }
	}
	set length [ns_set iget $headers content-length]
	if [string match "" $length] {set length -1}
	set err [catch {
	    while 1 {
		set buf [_ns_http_read $timeout $rfd $length]
		append page $buf
		if [string match "" $buf] break
		if {$length > 0} {
		    incr length -[string length $buf]
		    if {$length <= 0} break
		}
	    }
	} errMsg]
	ns_set free $headers
	close $rfd
	if $err {
	    global errorInfo
	    return -code error -errorinfo $errorInfo $errMsg
	}
    } errmgs ] {return -1}
    return $page

}

proc_doc util_report_successful_library_load {{extra_message ""}} "Should be called at end of private Tcl library files so that it is easy to see in the error log whether or not private Tcl library files contain errors." {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { [string compare $extra_message ""] == 0 } {
	set message "Done... $scrubbed_path"
    } else {
	set message "Done... $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

proc_doc exists_and_not_null { varname } {Returns 1 if the variable name exists in the caller's environment and is not the empty string.} {
    upvar 1 $varname var 
    return [expr { [info exists var] && ![empty_string_p $var] }] 
} 

proc_doc util_decode args {
    like decode in sql
    Takes the place of an if (or switch) statement -- convenient because it's
    compact and you don't have to break out of an ns_write if you're in one.
    args: same order as in sql: first the unknown value, then any number of
    pairs denoting "if the unknown value is equal to first element of pair,
    then return second element", then if the unknown value is not equal to any
    of the first elements, return the last arg
} {
    set args_length [llength $args]
    set unknown_value [lindex $args 0]
    
    # we want to skip the first & last values of args
    set counter 1
    while { $counter < [expr $args_length -2] } {
	if { [string compare $unknown_value [lindex $args $counter]] == 0 } {
	    return [lindex $args [expr $counter + 1]]
	}
	set counter [expr $counter + 2]
    }
    return [lindex $args [expr $args_length -1]]
}

proc_doc util_httpget {url {headers ""} {timeout 30} {depth 0}} "Just like ns_httpget, but first optional argument is an ns_set of headers to send during the fetch." {
    if {[incr depth] > 10} {
	return -code error "util_httpget:  Recursive redirection:  $url"
    }
    set http [ns_httpopen GET $url $headers $timeout]
    set rfd [lindex $http 0]
    close [lindex $http 1]
    set headers [lindex $http 2]
    set response [ns_set name $headers]
    set status [lindex $response 1]
    if {$status == 302} {
	set location [ns_set iget $headers location]
	if {$location != ""} {
	    ns_set free $headers
	    close $rfd
	    return [ns_httpget $location $timeout $depth]
	}
    }
    set length [ns_set iget $headers content-length]
    if [string match "" $length] {set length -1}
    set err [catch {
	while 1 {
	    set buf [_http_read $timeout $rfd $length]
	    append page $buf
	    if [string match "" $buf] break
	    if {$length > 0} {
		incr length -[string length $buf]
		if {$length <= 0} break
	    }
	}
    } errMsg]
    ns_set free $headers
    close $rfd
    if $err {
	global errorInfo
	return -code error -errorinfo $errorInfo $errMsg
    }
    return $page
}

# some procs to make it easier to deal with CSV files (reading and writing)
# added by philg@mit.edu on October 30, 1999

proc_doc util_escape_quotes_for_csv {string} "Returns its argument with double quote replaced by backslash double quote" {
    regsub -all {"} $string {\"}  result
    return $result
}

proc_doc set_csv_variables_after_query {} {

    You can call this after an ns_db getrow or ns_db 1row to set local
    Tcl variables to values from the database.  You get $foo, $EQfoo
    (the same thing but with double quotes escaped), and $QEQQ
    (same thing as $EQfoo but with double quotes around the entire
    she-bang).

} {
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $selection $set_variables_after_query_i] [ns_set value $selection $set_variables_after_query_i]
		set EQ[ns_set key $selection $set_variables_after_query_i] [util_escape_quotes_for_csv [string trim [ns_set value $selection $set_variables_after_query_i]]]
		set QEQQ[ns_set key $selection $set_variables_after_query_i] "\"[util_escape_quotes_for_csv [string trim [ns_set value $selection $set_variables_after_query_i]]]\""
		incr set_variables_after_query_i
	    }
    }
}

#"

proc_doc ad_page_variables {variable_specs} {
<pre>
Current syntax:

    ad_page_variables {var_spec1 [varspec2] ... }

    This proc handles translating form inputs into Tcl variables, and checking
    to see that the correct set of inputs was supplied.  Note that this is mostly a
    check on the proper programming of a set of pages.

Here are the recognized var_specs:

    variable				; means it's required
    {variable default-value}
      Optional, with default value.  If the value is supplied but is null, and the
      default-value is present, that value is used.
    {variable -multiple-list}
      The value of the Tcl variable will be a list containing all of the
      values (in order) supplied for that form variable.  Particularly useful
      for collecting checkboxes or select multiples.
      Note that if required or optional variables are specified more than once, the
      first (leftmost) value is used, and the rest are ignored.
    {variable -array}
      This syntax supports the idiom of supplying multiple form variables of the
      same name but ending with a "_[0-9]", e.g., foo_1, foo_2.... Each value will be
      stored in the array variable variable with the index being whatever follows the
      underscore.

QQ variables are automatically created by ad_page_variables.

Other elements of the var_spec are ignored, so a documentation string
describing the variable can be supplied.

Note that the default value form will become the value form in a "set"

Note that the default values are filled in from left to right, and can depend on
values of variables to their left:
ad_page_variables {
    file
    {start 0}
    {end {[expr $start + 20]}}
}
</pre>
} {
    set exception_list [list]
    set form [ns_getform]
    if { $form != "" } {
	set form_size [ns_set size $form]
	set form_counter_i 0

	# first pass -- go through all the variables supplied in the form
	while {$form_counter_i<$form_size} {
	    set variable [ns_set key $form $form_counter_i]
	    set value [ns_set value $form $form_counter_i]
	    check_for_form_variable_naughtiness $variable $value
	    set found "not"
	    # find the matching variable spec, if any
	    foreach variable_spec $variable_specs {
		if { [llength $variable_spec] >= 2 } {
		    switch -- [lindex $variable_spec 1] {
			-multiple-list {
			    if { [lindex $variable_spec 0] == $variable } {
				# variable gets a list of all the values
				upvar 1 $variable var
				lappend var $value
				set found "done"
				break
			    }
			}
			-array {
			    set varname [lindex $variable_spec 0]
			    set pattern "($varname)_(.+)"
			    if { [regexp $pattern $variable match array index] } {
				if { ![empty_string_p $array] } {
				    upvar 1 $array arr
				    set arr($index) [ns_set value $form $form_counter_i]
				}
				set found "done"
				break
			    }
			}
			default {
			    if { [lindex $variable_spec 0] == $variable } {
				set found "set"
				break
			    }
			}
		    }
		} elseif { $variable_spec == $variable } {
		    set found "set"
		    break
		}
	    }
	    if { $found == "set" } {
		upvar 1 $variable var
		if { ![info exists var] } {
		    # take the leftmost value, if there are multiple ones
		    set var $value
		}
	    }
	    incr form_counter_i
	}
    }

    # now make a pass over each variable spec, making sure everything required is there
    # and doing defaulting for unsupplied things that aren't required
    foreach variable_spec $variable_specs {
	set variable [lindex $variable_spec 0]
	upvar 1 $variable var

	if { [llength $variable_spec] >= 2 } {
	    if { ![info exists var] } {
		set default_value_or_flag [lindex $variable_spec 1]
		
		switch -- $default_value_or_flag {
		    -array {
			# don't set anything
		    }
		    -multiple-list {
			set var [list]
		    }
		    default {
			# Needs to be set.
			uplevel [list eval set $variable "\[subst [list $default_value_or_flag]\]"]
			# This used to be:
			#
			#   uplevel [list eval [list set $variable "$default_value_or_flag"]]
			#
			# But it wasn't properly performing substitutions.
		    }
		}
	    }

	    # no longer needed because we QQ everything by default now
	    #	    # if there is a QQ or qq or any variant after the var_spec,
	    #	    # make a "QQ" variable
	    #	    if { [regexp {^[Qq][Qq]$} [lindex $variable_spec 2]] && [info exists var] } {
	    #		upvar QQ$variable QQvar
	    #		set QQvar [DoubleApos $var]
	    #	    }

	} else {
	    if { ![info exists var] } {
		lappend exception_list "\"$variable\" required but not supplied"
	    }
	}

        # modified by rhs@mit.edu on 1/31/2000
	# to QQ everything by default (but not arrays)
        if {[info exists var] && ![array exists var]} {
	    upvar QQ$variable QQvar
	    set QQvar [DoubleApos $var]
	}

    }

    set n_exceptions [llength $exception_list]
    # this is an error in the HTML form
    if { $n_exceptions == 1 } {
	ns_returnerror 500 [lindex $exception_list 0]
	return -code return
    } elseif { $n_exceptions > 1 } {
	ns_returnerror 500 "<li>[join $exception_list "\n<li>"]\n"
	return -code return
    }
}

proc_doc page_validation {args} {
    This proc allows page arg, etc. validation.  It accepts a bunch of
    code blocks.  Each one is executed, and any error signalled is
    appended to the list of exceptions.
    Note that you can customize the complaint page to match the design of your site,
    by changing the proc called to do the complaining:
    it's [ad_parameter ComplainProc "" ad_return_complaint]

    The division of labor between ad_page_variables and page_validation 
    is that ad_page_variables
    handles programming errors, and does simple defaulting, so that the rest of
    the Tcl code doesn't have to worry about testing [info exists ...] everywhere.
    page_validation checks for errors in user input.  For virtually all such tests,
    there is no distinction between "unsupplied" and "null string input".

    Note that errors are signalled using the Tcl "error" function.  This allows
    nesting of procs which do the validation tests.  In addition, validation
    functions can return useful values, such as trimmed or otherwise munged
    versions of the input.
} {
    if { [info exists {%%exception_list}] } {
	error "Something's wrong"
    }
    # have to put this in the caller's frame, so that sub_page_validation can see it
    # that's because the "uplevel" used to evaluate the code blocks hides this frame
    upvar {%%exception_list} {%%exception_list}
    set {%%exception_list} [list]
    foreach validation_block $args {
	if { [catch {uplevel $validation_block} errmsg] } {
	    lappend {%%exception_list} $errmsg
	}
    }
    set exception_list ${%%exception_list}
    unset {%%exception_list}
    set n_exceptions [llength $exception_list]
    if { $n_exceptions != 0 } {
	set complain_proc [ad_parameter ComplainProc "" ad_return_complaint]
	if { $n_exceptions == 1 } {
	    $complain_proc $n_exceptions [lindex $exception_list 0]
	} else {
	    $complain_proc $n_exceptions "<li>[join $exception_list "\n<li>"]\n"
	}
	return -code return
    }
}

proc_doc sub_page_validation {args} {
    Use this inside a page_validation block which needs to check more than one thing.
    Put this around each part that might signal an error.
} {
    # to allow this to be at any level, we search up the stack for {%%exception_list}
    set depth [info level]
    for {set level 1} {$level <= $depth} {incr level} {
	upvar $level {%%exception_list} {%%exception_list}
	if { [info exists {%%exception_list}] } {
	    break
	}
    }
    if { ![info exists {%%exception_list}] } {
	error "sub_page_validation not inside page_validation"
    }
    foreach validation_block $args {
	if { [catch {uplevel $validation_block} errmsg] } {
	    lappend {%%exception_list} $errmsg
	}
    }
}

proc_doc validate_integer {field_name string} {
    Throws an error if the string isn't a decimal integer; otherwise
    strips any leading zeros (so this won't work for octals) and returns
    the result.  
} {
    if { ![regexp {^[0-9]+$} $string] } {
	error "$field_name is not an integer"
    }
    # trim leading zeros, so as not to confuse Tcl
    set string [string trimleft $string "0"]
    if { [empty_string_p $string] } {
	# but not all of the zeros
	return "0"
    }
    return $string
}

proc_doc validate_zip_code {field_name zip_string country_code} {

    Given a string, signals an error if it's not a legal zip code

} {
    if { $country_code == "" || [string toupper $country_code] == "US" } {
	if { [regexp {^[0-9][0-9][0-9][0-9][0-9](-[0-9][0-9][0-9][0-9])?$} $zip_string] } {
	    set zip_5 [string range $zip_string 0 4]
	    if {
		![db_0or1row zip_code_exists {
		    select 1
		      from dual
		     where exists (select 1
				     from zip_codes
				    where zip_code like :zip_5)
		}]
	    } {
		error "The entry for $field_name, \"$zip_string\" is not a recognized zip code"
	    }
	} else {
	    error "The entry for $field_name, \"$zip_string\" does not look like a zip code"
	}
    } else {
	if { $zip_string != "" } {
	    error "Zip code is not needed outside the US"
	}
    }
    return $zip_string
}

proc_doc validate_ad_dateentrywidget {field_name column form {allow_null 0}} {
} {
    set col $column
    set day [ns_set get $form "$col.day"]
    ns_set update $form "$col.day" [string trimleft $day "0"]
    set month [ns_set get $form "$col.month"]
    set year [ns_set get $form "$col.year"]

    # check that either all elements are blank
    # date value is formated correctly for ns_dbformvalue
    if { [empty_string_p "$day$month$year"] } {
	if { $allow_null == 0 } {
	    error "$field_name must be supplied"
	} else {
	    return ""
	}
    } elseif { ![empty_string_p $year] && [string length $year] != 4 } {
	error "The year must contain 4 digits."
    } elseif { [catch  { ns_dbformvalue $form $column date date } errmsg ] } {
	error "The entry for $field_name had a problem:  $errmsg."
    }

    return $date
}

proc_doc util_WriteWithExtraOutputHeaders {headers_so_far {first_part_of_page ""}} "Takes in a string of headers to write to an HTTP connection, terminated by a newline.  Checks \[ns_conn outputheaders\] and adds those headers if appropriate.  Adds two newlines at the end and writes out to the connection.  May optionally be used to write the first part of the page as well (saves a packet)" {
    ns_set put [ns_conn outputheaders] Server "[ns_info name]/[ns_info version]"
    set set_headers_i 0
    set set_headers_limit [ns_set size [ns_conn outputheaders]]
    while {$set_headers_i < $set_headers_limit} {
	append headers_so_far "[ns_set key [ns_conn outputheaders] $set_headers_i]: [ns_set value [ns_conn outputheaders] $set_headers_i]\r\n"
	incr set_headers_i
    }
    append entire_string_to_write $headers_so_far "\r\n" $first_part_of_page
    ns_write $entire_string_to_write
}

# we use this when we want to send out just the headers 
# and then do incremental ns_writes.  This way the user
# doesn't have to wait like if you used a single ns_return

proc ReturnHeaders {{content_type text/html}} {
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
     util_WriteWithExtraOutputHeaders $all_the_headers
     ns_startcontent -type $content_type
}

# All the following ReturnHeaders versions are obsolete;
# just set [ns_conn outputheaders].

proc ReturnHeadersNoCache {{content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
pragma: no-cache\r\n"

     ns_startcontent -type $content_type
}

proc ReturnHeadersWithCookie {cookie_content {content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
Set-Cookie:  $cookie_content\r\n"

     ns_startcontent -type $content_type
}

proc ReturnHeadersWithCookieNoCache {cookie_content {content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
Set-Cookie:  $cookie_content
pragma: no-cache\r\n"

     ns_startcontent -type $content_type
}

proc_doc ad_return_top_of_page {first_part_of_page {content_type text/html}} "Returns HTTP headers plus the top of the user-ivisible page.  Saves a TCP packet (and therefore some overhead) compared to using ReturnHeaders and an ns_write." {
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
     util_WriteWithExtraOutputHeaders $all_the_headers

    ns_startcontent -type $content_type

    if ![empty_string_p $first_part_of_page] {
	ns_write $first_part_of_page
    }
}

proc_doc apply {func arglist} {
    Evaluates the first argument with ARGLIST as its arguments, in the
    environment of its caller. Analogous to the Lisp function of the same name.
} {
    set func_and_args [concat $func $arglist]
    return [uplevel $func_and_args]
}

proc_doc safe_eval args {
    Version of eval that checks its arguments for brackets that may be
used to execute unsafe code.
} {
    foreach arg $args {
	if { [regexp {[\[;]} $arg] } {
	    return -code error "Unsafe argument to safe_eval: $arg"
	}
    }
    return [apply uplevel $args]
}

proc_doc lmap {list proc_name} {Applies proc_name to each item of the list, appending the result of each call to a new list that is the return value.} {
    set lmap [list]
    foreach item $list {
	lappend lmap [safe_eval $proc_name $item]
    }
    return $lmap
}

ad_proc -deprecated util_dbq {
    { 
        -null_is_null_p f
    }
    vars
} {
    Given a list of variable names this routine 
    creates variables named DBQvariable_name which can be used in 
    sql insert and update statements.  
    <p>
    If -null_is_null_p is t then we return the string "null" unquoted
    so that "update foo set var = $DBQvar where ..." will do what we want 
    if we default var to "null".
} {
    # This function really shouldn't be used
    #   foreach var $vars {
# 	upvar 1 $var val
#         if [info exists val] {
#             if { $null_is_null_p == "t" 
#                  && $val == {null} } {
#                 uplevel [list set DBQ$var {null}]
#             } else {
#                 uplevel [list set DBQ$var "'[DoubleApos [string trim $val]]'"]
#             }
#         }
#     }
}

proc_doc ad_decode { args } "this procedure is analogus to sql decode procedure. first parameter is the value we want to decode. this parameter is followed by a list of pairs where first element in the pair is convert from value and second element is convert to value. last value is default value, which will be returned in the case convert from values matches the given value to be decoded" {
    set num_args [llength $args]
    set input_value [lindex $args 0]

    set counter 1

    while { $counter < [expr $num_args - 2] } {
	lappend from_list [lindex $args $counter]
	incr counter
	lappend to_list [lindex $args $counter]
	incr counter
    }

    set default_value [lindex $args $counter]

    if { $counter < 2 } {
	return $default_value
    }

    set index [lsearch -exact $from_list $input_value]
    
    if { $index < 0 } {
	return $default_value
    } else {
	return [lindex $to_list $index]
    }
}

proc_doc ad_urlencode { string } "same as ns_urlencode except that dash and underscore are left unencoded." {
    set encoded_string [ns_urlencode $string]
    regsub -all {%2d} $encoded_string {-} encoded_string
    regsub -all {%5f} $encoded_string {_} ad_encoded_string
    return $ad_encoded_string
}

ad_proc ad_get_cookie {
    { -include_set_cookies t }
    name { default "" }
} { "Returns the value of a cookie, or $default if none exists." } {
    if { $include_set_cookies == "t" } {
	set headers [ns_conn outputheaders]
	for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
	    if { ![string compare [string tolower [ns_set key $headers $i]] "set-cookie"] && \
		    [regexp "^$name=(\[^;\]+)" [ns_set value $headers $i] "" "value"] } {
		return $value
	    }
	}
    }

    set headers [ns_conn headers]
    set cookie [ns_set iget $headers Cookie]
    if { [regexp "$name=(\[^;\]+)" $cookie match value] } {
	return $value
    }

    return $default
}

ad_proc ad_set_cookie {
    {
	-replace f
	-secure f
	-expires ""
	-max_age ""
	-domain ""
	-path "/"
    }
    name value
} { Sets a cookie. } {
    set headers [ns_conn outputheaders]
    if { $replace != "f" } {
	# Try to find an already-set cookie named $name.
	for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
	    if { ![string compare [string tolower [ns_set key $headers $i]] "set-cookie"] && \
		    [regexp "^$name=" [ns_set value $headers $i]] } {
		ns_set delete $headers $i
		break
	    }
	}
    }

    set cookie "$name=$value"

    if { $path != "" } {
	append cookie "; Path=$path"
    }

    if { ![string compare [string tolower $expires] "never"] } {
	append cookie "; Expires=Fri, 01-Jan-2010 01:00:00 GMT"
    } elseif { $expires != "" } {
	append cookie "; Expires=$expires"
    }

    if { $max_age != "" } {
	append cookie "; Max-Age=$max_age"
    }

    if { $domain != "" } {
	append cookie "; Domain=$domain"
    }

    if { $secure != "f" } {
	append cookie "; Secure"
    }

    ns_set put $headers "Set-Cookie" $cookie
}

proc_doc ad_run_scheduled_proc { proc_info } { Runs a scheduled procedure and updates monitoring information in the shared variables. } {
    # Grab information about the scheduled procedure.
    set thread [lindex $proc_info 0]
    set once [lindex $proc_info 1]
    set interval [lindex $proc_info 2]
    set proc [lindex $proc_info 3]
    set args [lindex $proc_info 4]
    set time [lindex $proc_info 5]
    set count 0
    set debug [lindex $proc_info 7]

    ns_mutex lock [nsv_get ad_procs mutex]
    set procs [nsv_get ad_procs .]

    # Find the entry in the shared variable. Splice it out.
    for { set i 0 } { $i < [llength $procs] } { incr i } {
	set other_proc_info [lindex $procs $i]
	for { set j 0 } { $j < 5 } { incr j } {
	    if { [lindex $proc_info $j] != [lindex $other_proc_info $j] } {
		break
	    }
	}
	if { $j == 5 } {
	    set count [lindex $other_proc_info 6]
	    set procs [lreplace $procs $i $i]
	    break
	}
    }

    if { $once == "f" } {
	# The proc will run again - readd it to the shared variable (updating ns_time and
	# incrementing the count).
	lappend procs [list $thread $once $interval $proc $args [ns_time] [expr { $count + 1 }] $debug]
    }
    nsv_set ad_procs . $procs

    ns_mutex unlock [nsv_get ad_procs mutex]

    if { $debug == "t" } {
	ns_log "Notice" "Running scheduled proc $proc..."
    }
    # Actually run the procedure.
    eval [concat [list $proc] $args]
    if { $debug == "t" } {
	ns_log "Notice" "Done running scheduled proc $proc."
    }
}

# Initialize NSVs for ad_schedule_proc.
if { [apm_first_time_loading_p] } {
    nsv_set ad_procs mutex [ns_mutex create]
    nsv_set ad_procs . ""
}

ad_proc ad_schedule_proc {
    {
	-thread f
	-once f
	-debug t
	-all_servers f
    }
    interval
    proc
    args
} { Replacement for ns_schedule_proc, allowing us to track what's going on. Can be monitored via /admin/monitoring/schedule-procs.tcl. The procedure defaults to run on only the canonical server unless the all_servers flag is set to true. } {
    # we don't schedule a proc to run if we have enabled server clustering,
    # we're not the canonical server, and the procedure was not requested to run on all servers.
    if { [server_cluster_enabled_p] && ![ad_canonical_server_p] && $all_servers == "f" } {
        return
    } 

    # Protect the list of scheduled procs with a mutex.
    ns_mutex lock [nsv_get ad_procs mutex]
    set proc_info [list $thread $once $interval $proc $args [ns_time] 0 $debug]
    ns_log "Notice" "Scheduling proc $proc"
    
    # Add to the list of scheduled procedures, for monitoring.
    set procs [nsv_get ad_procs .]
    lappend procs $proc_info
    nsv_set ad_procs . $procs
    ns_mutex unlock [nsv_get ad_procs mutex]

    set my_args [list]
    if { $thread == "t" } {
	lappend my_args "-thread"
    }
    if { $once == "t" } {
	lappend my_args "-once"
    }

    # Schedule the wrapper procedure (ad_run_scheduled_proc).
    eval [concat [list ns_schedule_proc] $my_args [list $interval ad_run_scheduled_proc [list $proc_info]]]
}

proc util_ReturnMetaRefresh { url { seconds_delay 0 }} {
    ReturnHeaders
    ns_write "
    <head>
    <META HTTP-EQUIV=\"REFRESH\" CONTENT=\"$seconds_delay;URL=$url\">
    </head>
    <body>
    If your browser does not automatically redirect you, please go <a href=$url>here</a>.
    </body>"
}

# branimir 2000/04/25 ad_returnredirect and helper procs :
#    util_complete_url_p util_absolute_path_p util_current_location
#    util_current_directory   
# See: http://www.arsdigita.com/bboard/q-and-a-fetch-msg.tcl?msg_id=0003eV

ad_proc ad_returnredirect {{} target_url} {
  A replacement for ns_returnredirect.  It uses ns_returnredirect but is better in
  two important aspects:
  <ul>
     <li>When the supplied target_url isn't complete, (e.g. /foo/bar.tcl or foo.tcl)
         the prepended location part is constructed by looking at the HTTP 1.1 Host header.
     <li>If an URL relative to the current directory is supplied (e.g. foo.tcl)
         it prepends location and directory.
  </ul>
} {
  if {[util_complete_url_p $target_url]} {
      # http://myserver.com/foo/bar.tcl style - just pass to ns_returnredirect
      set url $target_url
  } elseif {[util_absolute_path_p $target_url]} {
      # /foo/bar.tcl style - prepend the current location:
      set url [util_current_location]$target_url
  } else {
      # URL is relative to current directory.
      set url [util_current_location][util_current_directory]$target_url
  }
  #Ugly workaround to deal with IE5.0 bug handling multipart/form-data using 
  #Meta Refresh page instead of a redirect. 
  # jbank@arsdigita.com 6/7/2000
  set use_metarefresh_p 0
  set type [ns_set iget [ns_conn headers] content-type]
  if {[string match *multipart/form-data* [string tolower $type]]} {
      set user_agent [ns_set get [ns_conn headers] User-Agent]
      set use_metarefresh_p [regexp -nocase "msie" $user_agent match]
  }
  if {$use_metarefresh_p != 0} {
      util_ReturnMetaRefresh $url 
  } else {
      ns_returnredirect $url
  }
}

ad_proc util_complete_url_p {{} string} {
  Determine whether string is a complete URL, i.e.
  wheteher it begins with protocol: where protocol
  consists of letters only.
} {
  if {[regexp -nocase {^[a-z]+:} $string]} {
     return 1
  } else {
     return 0
  }
}

ad_proc util_absolute_path_p {{} path} {
   Check whether the path begins with a slash
} {
   set firstchar [string index $path 0]
   if {[string compare $firstchar /]} {
        return 0
   } else {
        return 1
   }
}

ad_proc util_current_location {{}} {
   Like ns_conn location - Returns the location string of the current
   request in the form protocol://hostname[:port] but it looks at the
   Host header, that is, takes into account the host name the client
   used although it may be different from the host name from the server
   configuration file.  If the Host header is missing or empty util_current_location
   falls back to ns_conn location.
} {
   set host_from_header [ns_set iget [ns_conn headers] Host]
   # host_from_header now hopefully contains hostname[:port]
   set location_from_config_file [ns_conn location]
   if {[empty_string_p $host_from_header]} {
      # Hmm, there is no Host header.  This must be
      # an old browser such as MSIE 3.  All we can do is:
      return $location_from_config_file
   } else {
      # Replace the hostname[:port] part of $location_from_config_file with $host_from_header:
      regsub -nocase {(^[a-z]+://).*} \
                $location_from_config_file \\1$host_from_header location_from_host_header
      return $location_from_host_header
   }
}

ad_proc util_current_directory {{}} {
    Returns the directory of the current URL.
    <p>
    We can't just use [file dirname [ns_conn url]] because
    we want /foo/bar/ to return /foo/bar/ and not /foo  .
    <p>
    Also, we want to return directory WITH the trailing slash
    so that programs that use this proc don't have to treat
    the root directory as a special case.
} {
   set path [ns_conn url]

   set lastchar [string range $path [expr [string length $path]-1] end]
   if {![string compare $lastchar /]} {
        return $path
   } else { 
        set file_dirname [file dirname $path]
        # Treat the case of the root directory special
        if {![string compare $file_dirname /]} {
            return /
        } else {
            return  $file_dirname/
        }
   }
}

proc util_aolserver_2_p {} {
    if {[string index [ns_info version] 0] == "2"} {
	return 1
    } else {
	return 0
    }
}

proc_doc ad_chdir_and_exec { dir arg_list } { chdirs to $dir and executes the command in $arg_list. We'll probably want to improve this to be thread-safe. } {
    cd $dir
    eval exec $arg_list
}

proc_doc ad_call_proc_if_exists { proc args } {

Calls a procedure with particular arguments, only if the procedure is defined.

} {
    if { [llength [info procs $proc]] == 1 } {
	eval $proc $args
    }
}

ad_proc -public ad_get_tcl_call_stack { {level -2} } {
    Returns a stack trace from where the caller was called.

    @param level The level to start from, relative to this
    proc. Defaults to -2, meaning the proc that called this 
    proc's caller.

    @author Lars Pind (lars@pinds.com)
 } {
    set stack ""
    for { set x [expr [info level] + $level] } { $x > 0 } { incr x -1 } {
	append stack "    called from [info level $x]\n"
    }
    return $stack
}

ad_proc -public ad_ns_set_to_tcl_vars { 
    {-duplicates overwrite}
    {-level 1}
    set_id
} {
    Takes an ns_set and sets variables in the caller's environment
    correspondingly, i.e. if key is foo and value is bar, the Tcl var
    foo is set to bar.

    @param duplicates This optional switch argument defines what happens if the
    Tcl var already exists, or if there are duplicate entries for the same key.
    <code>overwrites</code> just overwrites the var, which amounts to letting the 
    ns_set win over pre-defined vars, and later entries in the ns_set win over 
    earlier ones. <code>ignore</code> means the variable isn't overwritten.
    <code>fail</code> will make this proc fail with an error. This makes it 
    easier to track subtle errors that could occur because of unpredicted name 
    clashes.

    @param level The level to upvar to.

    @author Lars Pind (lars@pinds.com)
} {
    if { [lsearch -exact {ignore fail overwrite} $duplicates] == -1 } {
	return -code error "The optional switch duplicates must be either overwrite, ignore or fail"
    }
    
    set size [ns_set size $set_id]
    for { set i 0 } { $i < $size } { incr i } {
	set varname [ns_set key $set_id $i]
	upvar $level $varname var
	if { [info exists var] } {
	    switch $duplicates {
		fail {
		    return -code error "ad_ns_set_to_tcl_vars tried to set the var $varname which is already set"
		}
		ignore {
		    # it's already set ... don't overwrite it
		    continue
		}
	    }
	}
	set var [ns_set value $set_id $i]
    }
}

ad_proc -public -deprecated -warn ad_tcl_vars_to_ns_set { 
    -set_id
    -put:boolean
    args 
} {
    Takes a list of variable names and <code>ns_set update</code>s values in an ns_set
    correspondingly: key is the name of the var, value is the value of
    the var. The caller is (obviously) responsible for freeing the set if need be.

    @param set_id If this switch is specified, it'll use this set instead of 
    creating a new one.
    
    @param put If this boolean switch is specified, it'll use <code>ns_set put</code> instead 
    of <code>ns_set update</code> (update is default)

    @param args A number of variable names that will be transported into the ns_set.

    @author Lars Pind (lars@pinds.com)

} {
    if { ![info exists set_id] } {
	set set_id [ns_set create]
    }

    if { $put_p } {
	set command put
    } else {
	set command update
    }

    foreach varname $args {
	upvar $varname var
	ns_set $command $set_id $varname $var
    }
    return $set_id
}

ad_proc -public ad_tcl_vars_list_to_ns_set { 
    -set_id
    -put:boolean
    vars_list
} {
    Takes a TCL list of variable names and <code>ns_set update</code>s values in an ns_set
    correspondingly: key is the name of the var, value is the value of
    the var. The caller is (obviously) responsible for freeing the set if need be.

    @param set_id If this switch is specified, it'll use this set instead of 
    creating a new one.
    
    @param put If this boolean switch is specified, it'll use <code>ns_set put</code> instead 
    of <code>ns_set update</code> (update is default)

    @param args A TCL list of variable names that will be transported into the ns_set.

    @author Lars Pind (lars@pinds.com)

} {
    if { ![info exists set_id] } {
	set set_id [ns_set create]
    }

    if { $put_p } {
	set command put
    } else {
	set command update
    }

    foreach varname $vars_list {
	upvar $varname var
	ns_set $command $set_id $varname $var
    }
    return $set_id
}

ad_proc -public ad_tcl_list_list_to_ns_set { 
    -set_id
    -put:boolean
    kv_pairs 
} {

    Takes a list of lists of key/value pairs and <code>ns_set update</code>s
    values in an ns_set.

    @param set_id If this switch is specified, it'll use this set instead of
    creating a new one.

    @param put If this boolean switch is specified, it'll use
    <code>ns_set put</code> instead of <code>ns_set update</code>
    (update is default)

    @param kv_pairs A list of lists containing key/value pairs to be stuffed into
    the ns_set

    @author Yonatan Feldman (yon@arsdigita.com)

} {

    if { ![info exists set_id] } {
	set set_id [ns_set create]
    }

    if { $put_p } {
	set command put
    } else {
	set command update
    }

    foreach kv_pair $kv_pairs {
	ns_set $command $set_id [lindex $kv_pair 0] [lindex $kv_pair 1]
    }

    return $set_id
}

ad_proc -public ad_ns_set_keys {
    -colon:boolean
    {-exclude ""}
    set_id
} {
    Returns the keys of a ns_set as a Tcl list, like <code>array names</code>.
    
    @param colon If set, will prepend all the keys with a colon; useful for bind variables
    @param exclude Optional Tcl list of key names to exclude

    @author Lars Pind (lars@pinds.com)
    
} {
    set keys [list]
    set size [ns_set size $set_id]
    for { set i 0 } { $i < $size } { incr i } {
	set key [ns_set key $set_id $i]
	if { [lsearch -exact $exclude $key] == -1 } {
	    if { $colon_p } { 
		lappend keys ":$key"
	    } else {
		lappend keys $key
	    }
	}
    }
    return $keys
}

ad_proc -public util_wrap_list {
    { -eol " \\" }
    { -indent 4 }
    { -length 70 }
    items
} {

    Wraps text to a particular line length.

    @param eol the string to be used at the end of each line.
    @param indent the number of spaces to use to indent all lines after the
        first.
    @param length the maximum line length.
    @param items the list of items to be wrapped. Items are
        HTML-formatted. An individual item will never be wrapped onto separate
        lines.

} {
    set out "<pre>"
    set line_length 0
    foreach item $items {
	regsub -all {<[^>]+>} $item "" item_notags
	if { $line_length > $indent } {
	    if { $line_length + 1 + [string length $item_notags] > $length } {
		append out "$eol\n"
		for { set i 0 } { $i < $indent } { incr i } {
		    append out " "
		}
		set line_length $indent
	    } else {
		append out " "
		incr line_length
	    }
	}
	append out $item
	incr line_length [string length $item_notags]
    }
    append out "</pre>"
    return $out
}


ad_proc -public ad_export_dynamic_form_vars { 
    {
	-array "dynamic_vars"
    }
    args
} {
    Converts every variable specified in args into a form variable array suitable for use with <code>ad_page_contract</code>.
    Call this function within a form to export the variables.  It can be used safely with <code>export_form_vars</code><p>Example:
    <pre>
set user_id [ad_verify_and_get_user_id]
set password "hahaha"
set user_name [db_string name_get {
    set count 0
    set hidden ""
    foreach var $args {
	upvar 1 $var value
	if { [info exists value] } {
	    append hidden "<input type=hidden name=$array.$count value=$var>
<input type=hidden name=$array.$count value=\"[util_quotehtml $value]\">"
	incr count
	}
    }
    return $hidden
}]

set page_content "
This page 
&lt;form method=GET action=contract-test.tcl&gt;
[export_form_vars user_name]
[ad_export_dynamic_form_vars user_id password]
&lt;input type=submit&gt;
&lt;/form&gt;
"
doc_return  200 text/html $page_content
    </pre>

    @param array The name of the form variable array to be created.  You need to use this name on the page receiving
    the input from the form.
    @author Bryan Quinn
    @date July 11, 2000
    @see ad_import_dynamic_form_vars
} {
    select first_names || ' ' || last_name as user_name from users 
    where user_id = :user_id
}


ad_proc -public ad_import_dynamic_form_vars {
    {
	-array dynamic_vars
	-index ""
	-set_vars:boolean
    }
} {

    Searches through an array specified by <code>-array</code> for dynamic form variables and converts to a list of key/value pairs,
    optionally setting the variables in the caller's environment.  The returned list matches the input to <code>ad_export_dynamic_form_vars</code> 
    from the calling page.  To use this function, add a variable to the <code>ad_page_contract</code> on the page
    that is receiving the form variables called <code>dynamic_vars</code> that is flagged:array,multiple,optional.  
    Alternatively, you can use whatever name you want, but be to sure to specify that by using the -array flag. 
    Then in the body of the page, call this function to get back the list of key value pairs.<p>
    Example:
    <pre>

set page_content ""
# We have an ad_page_contract with <code>dynamic_vars:array,multiple,optional</code> defined
set dynamic_list [ad_import_dynamic_form_vars -set_vars]
append page_content "Retrieving dynamic form variables for $user_name:<br>"
foreach item $dynamic_list {
    append page_content "Key: [lindex $item 0] ; Value: [lindex $item 1]<br>"
}

append page_content "<p>We used -set_vars so the vars are declared in the enviroment as well.<br>"
foreach item $dynamic_list {
    append page_content "The value of [lindex $item 0] is [subst $[lindex $item 0]]. <br>"
}

doc_return 200 text/html $page_content
    </pre>
    
    @param array The base name of the dynamic form variables.  
    @param index An optional list of the form (array_name var1 ... varN) where array_name is a name of an array variable 
var1 through varN are the indices into the array.  If this is specified, variables of the form array_name(var1) are accumulated in 
the list to be returned.  This is useful if the incoming form variables are genearted from &lt;INPUT&gt; tags in the HTML form in which
case ad_export_dynamic_form_variables cannot be used. -array is ignored if you specify this flag.
    @param set_vars If set, all of the dynamic variables will be set in the page's environment overwriting previous values. 
    @see ad_export_dynamic_form_vars
    @author Bryan Quinn
    @date July 11, 2000

} {
    set var_list [list]
    set count 0

    # The user has specified an index, so these variables must
    # have been coming from HTML forms.
    if { ![empty_string_p $index] } {
	set array_name [lindex $index $count]
	upvar $array_name dynamic_vars
	for { incr count } { $count < [llength $index] } { incr count } {
	    set item_name [lindex $index $count]
	    if { [info exists dynamic_vars($item_name)] } {
		lappend var_list [list $item_name $dynamic_vars($item_name)]
		if $set_vars_p {
		    upvar $item_name $item_name
		    set $item_name $dynamic_vars($item_name)
		}
	    }
	}
    } else {    
	upvar $array dynamic_vars
	while { [info exists dynamic_vars($count)] } {
	    set item $dynamic_vars($count)
	    set item_name [lindex $item 0]
	    set item_value [lindex $item 1]
	    lappend var_list [list $item_name $item_value]
	    if $set_vars_p {
		upvar $item_name $item_name
		set $item_name $item_value
	    }
	    incr count
	}
    }
    return $var_list
}


ad_proc -public ad_export_vars { 
    -form:boolean
    {-exclude {}}
    {-override {}}
    {include {}}
} {
    Helps export variables from one page to the next, 
    either as URL variables or hidden form variables.
    It'll reach into arrays and grab either all values or individual values
    out and export them in a way that will be consistent with the 
    ad_page_contract :array flag.
    
    <p>

    Example:

    <blockquote><pre>doc_body_append [ad_export_vars { msg_id user(email) { order_by date } }]</pre></blockquote>
    will export the variable <code>msg_id</code> and the value <code>email</code> from the array <code>user</code>,
    and it will export a variable named <code>order_by</code> with the value <code>date</code>.

    <p>
    
    The args is a list of variable names that you want exported. You can name 

    <ul>
    <li>a scalar varaible, <code>foo</code>,
    <li>the name of an array, <code>bar</code>, 
    in which case all the values in that array will get exported, or
    <li>an individual value in an array, <code>bar(baz)</code>
    <li>a list in [array get] format { name value name value ..}.
    The value will get substituted normally, so you can put a computation in there.
    </ul>

    <p>

    A more involved example:
    <blockquote><pre>set my_vars { msg_id user(email) order_by }
doc_body_append [ad_export_vars -override { order_by $new_order_by } $my_vars]</pre></blockquote>

    @param form set this parameter if you want the variables exported as hidden form variables,
    as opposed to URL variables, which is the default.

    @param exclude takes a list of names of variables you don't want exported, even though 
    they might be listed in the args. The names take the same form as in the args list.

    @param override takes a list of the same format as args, which will get exported no matter
    what you have excluded.

    @author Lars Pind (lars@pinds.com)
    @creation-date 21 July 2000
} {

    ####################
    #
    # Build up an array of values to export
    #
    ####################

    array set export [list]

    set override_p 0
    foreach argument { include override } {
	foreach arg [set $argument] {
	    if { [llength $arg] == 1 } { 
		if { $override_p || [lsearch -exact $exclude $arg] == -1 } {
		    upvar $arg var
		    if { [array exists var] } {
			# export the entire array
			foreach name [array names var] {
			    if { $override_p || [lsearch -exact $exclude "${arg}($name)"] == -1 } {
				set export($arg.$name) $var($name)
			    }
			}
		    } elseif { [info exists var] } {
			if { $override_p || [lsearch -exact $exclude $arg] == -1 } {
			    # if the var is part of an array, we'll translate the () into a dot.
			    set left_paren [string first ( $arg]
			    if { $left_paren == -1 } {
				set export($arg) $var
			    } else {
				# convert the parenthesis into a dot before setting
				set export([string range $arg 0 [expr { $left_paren - 1}]].[string \
					range $arg [expr { $left_paren + 1}] end-1]) $var
			    }
			}
		    }
		}
	    } elseif { [llength $arg] %2 == 0 } {
		foreach { name value } $arg {
		    if { $override_p || [lsearch -exact $exclude $name] == -1 } {
			set left_paren [string first ( $name]
			if { $left_paren == -1 } {
			    set export($name) [lindex [uplevel list \[subst [list $value]\]] 0]
			} else {
			    # convert the parenthesis into a dot before setting
			    set export([string range $arg 0 [expr { $left_paren - 1}]].[string \
				    range $arg [expr { $left_paren + 1}] end-1]) \
				    [lindex [uplevel list \[subst [list $value]\]] 0]
			}
		    }
		}
	    } else {
		return -code error "All the exported values must have either one or an even number of elements"
	    }
	}
	incr override_p
    }
    
    ####################
    #
    # Translate this into the desired output form
    #
    ####################

    if { !$form_p } {
	set export_list [list]
	foreach varname [array names export] {
	    lappend export_list "[ns_urlencode $varname]=[ns_urlencode $export($varname)]"
	}
	return [join $export_list &]
    } else {
	set export_list [list]
	foreach varname [array names export] {
	    lappend export_list "<input type=hidden name=\"[ad_quotehtml $varname]\"\
		    value=\"[ad_quotehtml $export($varname)]\">"
	}
	return [join $export_list \n]
    }
}

proc philg_ns_set_to_tcl_string_cat_values {set_id} {
    set result_list [list]
    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	lappend result_list "[ns_set value $set_id $i]"
    }
    return [join $result_list " "]
}


ad_proc value_if_exists { var_name } {
    If the specified variable exists in the calling environment,
    returns the value of that variables. Otherwise, returns the
    empty_string.
} {
    upvar $var_name $var_name
    if [info exists $var_name] {
        return [set $var_name]
    }
}

