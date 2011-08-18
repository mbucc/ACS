# $Id: utils-extra.tcl,v 3.0 2000/02/06 03:14:10 ron Exp $
proc_doc export_form_value { var_name {default ""} } "Returns a properly formatted value part of a form field." {

    # Returns the value part of a form field ( value=\"foo\" ) for text fields. 
    # if the variable var_name exists in the callers environment, the value
    # of var_name is used as the value.  Otherwise, the value of default is used. 
    # Quotes are converted to &quot;

    if [eval uplevel {info exists $var_name}] {
	upvar $var_name value
	return " value=\"[philg_quote_double_quotes $value]\" "
    } else {
	return " value=\"[philg_quote_double_quotes $default]\" "
    }
}

# philg founded this horribly named procedure on March 2, 1999
# it should not be used.
# Tracy:  you've 
#   1) misunderstood why procedures are named "export_.."; it is because
#      they send variables from one Tcl page to another.  This procedure
#      is unrelated to those.
#   2) set us up for some horrible bugs if we ever move from Oracle to
#      a strict ANSI database.  '[export_var html_p]' will insert NULL into 
#      Oracle if html_p is undefined.  But Oracle reserves the right to change
#      this oddity in the future.  In that case, you'd probably get an error.

proc_doc export_var { var_name { default "" } } "Returns a variable's value if it exists.  This can be used to protect against undefined variables." {

    # export_var protects against undefined variables
    # Returns the value of the variable if it exists in the caller's environment. 
    # Otherwise, returns default.

    if [eval uplevel {info exists $var_name}] {
	upvar $var_name value
	return "$value"
    } else {
	return "$default"
    }
}

# this is a little better (redesigned by philg and Tracy)
proc util_quote_var_for_sql { varname { type text } } {
    if [eval uplevel {info exists $varname}] {
	upvar $varname value
	return "[ns_dbquotevalue $value $type]"
    } else {
	return "NULL"
    }
}

proc_doc util_lmember_p { value list } "is value an element in the list" {

    if { [lsearch -exact $list $value] > -1 } {
	return 1
    }
    return 0
}

proc_doc util_ldelete { list value } "deletes value from the list" {
    set ix [lsearch -exact $list $value]
    if {$ix >= 0} {
	return [lreplace $list $ix $ix]
    } else {
	return $list
    }
}

proc_doc util_kill_cache_url {} "often netscape caches something we don't want to be cached. pragma: no-cache directive doesn't work always with netscape, either. solution is to pass a variable to a file, which will have a distinct value each time function is called. this function will pass a unix's time in seconds (pretty much guaranteed to be unique) in the variable called no_cache. usage of this function should be something like this <a href=example.tcl?test_var=whatever?\[util_kill_cache_url\]>example</a>" {
    return "no_cache=[ns_time]"
}

proc_doc util_kill_cache_form {} "often netscape caches something we don't want to be cached. pragma: no-cache directive doesn't work always with netscape, either. solution is to pass a variable to a file, which will have a distinct value each time function is called. this function will pass a unix's time in seconds (pretty much guaranteed to be unique) in the variable called no_cache. usage of this function should be something like this <form method=post action=\"/whatever\"> \[util_kill_cache_form\]  form stuff </form>" {
    return "<input type=hidden name=no_cache value=[ns_time]>
    "
}