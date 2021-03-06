ad_library {

    Routines to support documenting pages and processing query arguments.

    @author Lars Pind (lars@pinds.com)
    @author Jon Salz (jsalz@mit.edu)
    @author Yonatan Feldman (yon@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date 16 June 2000
    @cvs-id tcl-documentation-procs.tcl,v 1.1.4.90 2001/01/12 21:06:29 khy Exp
}

ad_proc ad_page_contract_filter_proc { filter } {
    Returns the proc that executes the given ad_page_contract filter.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return [lindex [nsv_get ad_page_contract_filters $filter] 1]
}



####################
#
# Documentation-mode procs
#
####################

ad_proc api_page_documentation_mode_p { } {

    Determines whether the thread is in "gathering documentation" or "executing the page" mode.

    @return true if the thread is in "gathering documentation" mode, or false otherwise.
    @see doc_set_page_documentation_mode_p

} {
    global ad_conn
    if { [info exists ad_conn(api_page_documentation_mode_p)] } {
	return $ad_conn(api_page_documentation_mode_p)
    }
    return 0
}

ad_proc doc_set_page_documentation_mode { page_documentation_mode_p } {

    Set a flag in the environment determining whether the thread is in
    "gathering documentation" or "executing the page" mode.

    @param page_documentation_mode_p true to set the "gathering documentation" flag,
        or false to clear it.
    @see api_page_documentation_mode_p
} {
    global ad_conn
    set ad_conn(api_page_documentation_mode_p) $page_documentation_mode_p
}

#################### 
#
# Complaints procs
#
####################

# global: 
# ad_page_contract_complaints: list of error messages reported using ad_complain
# 
# ad_page_contract_errorkeys: [list] is a stack of errorkeys
#
# ad_page_contract_error_string(name:flag) "the string"
# 

ad_proc -private ad_complaints_init {} {
    Initializes the complaints system.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    global ad_page_contract_complaints ad_page_contract_errorkeys
    set ad_page_contract_complaints [list]
    set ad_page_contract_errorkeys [list]
}

ad_proc -public ad_complain { 
    {-key ""}
    {message ""}
} {
    Used to report a problem while validating user input. This proc does not 
    in itself make your code terminate, you must call return if you do not 
    want control to return to the caller.

    <p>

    @param key
    
    @param message 

    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    global ad_page_contract_complaints ad_page_contract_errorkeys ad_page_contract_error_string
    if { [empty_string_p $key] && [info exists ad_page_contract_errorkeys] } {
	set key [lindex $ad_page_contract_errorkeys 0]
    }
    
    if { [info exists ad_page_contract_error_string($key)] } {
	ad_complain_add_complaint $ad_page_contract_error_string($key)
    } elseif { [empty_string_p $message] } {
	ad_complain_add_complaint "Filter \"$key\" complained"
    } else {
	ad_complain_add_complaint $message
    }
}

ad_proc -private ad_complain_add_complaint { message } { 
    A helper proc that adds a complaint to the list of complaints. 
    Ensures that we don't make the exact same complaint twice.

    @author Lars Pind (lars@pinds.com)
    @creation-date 20 September 2000
} {
    global ad_page_contract_complaints 
    if { [lsearch -exact $ad_page_contract_complaints $message] == -1 } {
	lappend ad_page_contract_complaints $message
    }
    
}

ad_proc -private ad_complaints_with_key { errorkey code } {
    Sets the default errorkey to be used when ad_complaint is called. This essentially maintains
    a stack of errorkeys, so we can just say ad_complain without any arguments, when called 
    from within some code that is surrounded by ad_complaints_with_key.
    
    @author Lars Pind
    @creation-date 25 July 2000
} {
    global ad_page_contract_errorkeys
    set ad_page_contract_errorkeys [concat $errorkey $ad_page_contract_errorkeys]
    uplevel 1 $code
    set ad_page_contract_errorkeys [lrange $ad_page_contract_errorkeys 1 end]
}

ad_proc -private ad_complaints_count {} {
    Returns the number of complaints encountered so far.
    
    @author Lars Pind
    @creation-date 25 July 2000
} {
    global ad_page_contract_complaints
    return [llength $ad_page_contract_complaints]
}

ad_proc -private ad_complaints_get_list {} {
    Returns the list of complaints encountered so far.

    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    global ad_page_contract_complaints
    return $ad_page_contract_complaints
}

ad_proc -private ad_complaints_parse_error_strings { errorstrings } {
    Parses the error-strings argument to ad_page_contract and stores the 
    result in global variables, so it can be used by ad_complain.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    global ad_page_contract_error_string
    array set ad_page_contract_error_string [list]

    foreach { errorkeys text } $errorstrings {
	foreach errorkey $errorkeys {
	    if { ![regexp {^([^:]+)(?::([a-zA-Z0-9_,]*))?$} $errorkey match name flags] } {
		return -code error "Error name '$error' doesn't have the right format. It must be var\[:flag\]"
	    }

	    if { [empty_string_p $flags] } {
		set ad_page_contract_error_string($name) $text
	    } else {
		foreach flag [split $flags ,] {
		    if { ![empty_string_p $flag] } {
			set ad_page_contract_error_string($name:$flag) $text
		    } else {
			set ad_page_contract_error_string($name) $text
		    }
		}
	    }
	}
    }
}

####################
#
# Validation OK procs
#
####################

# global:  
# ad_page_contract_validations_passed(name) 1               the variable was supplied
# ad_page_contract_validations_passed(name:flag) 1          the filter returned 1
# ad_page_contract_validations_passed(name:-all) 1          all filters returned 1
#

ad_proc ad_page_contract_set_validation_passed { name {flag ""} {passed_p 1}} { 
    Call this to signal that a certain validation block has passed successfully. 
    This can be tested later using ad_page_contract_get_validation_passed_p.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    global ad_page_contract_validations_passed
    if { [string first : $name] != -1 } {
	set name_flag_list [split $name :]
	set name [lindex $name_flag_list 0]
	set flag [lindex $name_flag_list 1]
    }
    if { ![empty_string_p $flag] } {
	set key $name:$flag
    } else {
	set key $name
    }

    if { $passed_p } {
	set ad_page_contract_validations_passed($key) 1
    } else {
	set ad_page_contract_validations_passed($name:-all) 0
    }
}

ad_proc ad_page_contract_get_validation_passed_p { name {flag ""} } { 
    Find out whether the named validation block has been passed or not.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    global ad_page_contract_validations_passed
    if { [string first : $name] != -1 } {
	set name_flag_list [split $name :]
	set name [lindex $name_flag_list 0]
	set flag [lindex $name_flag_list 1]
    }
    if { ![empty_string_p $flag] } {
	set key $name:$flag
    } else {
	set key $name
    }

    if { [string equal $flag -all] } {
	return ![info exists ad_page_contract_validations_passed($key)]
    } else {
	return [info exists ad_page_contract_validations_passed($key)]
    } 
}

####################
#
# Eval helper proc
#
####################

ad_proc ad_page_contract_eval { args } {
    This just uplevels it's args. We need this proc, so that the return -code statements
    get processed correctly inside a catch block. This processing is namely done by the
    proc invocation.

    @author Lars Pind (lars@pinds.com) 
    @author 25 July 2000
} {
    uplevel 1 $args
}

####################
#
# ad_page_contract
# 
####################

# global: 

# ad_page_contract_variables: list of all the variables, required or
#   optional, specified in the ad_page_contract call error

ad_proc -public ad_page_contract {
    -type
    -properties
    docstring
    args
} {
    Specifies the contract between programmer and graphic designer for a page.
    When called with the magic "documentation-gathering" flag set (to
    be defined), the proc will record the information about this page, so 
    it can be displayed as documentation. When called during normal
    page execution, it will validate the query string and set
    corresponding variables in the caller's environment.
    
    <p>

    Example:
   
    <blockquote><pre>ad_page_contract  {
    Some documentation.
    &#64;author me (my@email)
    &#64;cvs-id $<foo>Id</foo>$
} {
    foo
    bar:integer,notnull,multiple,trim
    {greble:integer {[expr [lindex $bar 0] + 1]}}
} -validate {
    greble_is_in_range -requires {greble:integer} {
	if { $greble < 1 || $greble > 100 } {
	    ad_complain
	}
    }
    greble_exists -requires { greble_is_in_range } {
        global greble_values
	if { ![info exists greble_values($greble)] } {
	    ad_complain "There's no greble with that value"
	}
    }
} -errors {
    foo {error message goes here}
    bar:,integer,notnull {another error message}
    greble_is_in_range {Greble must be between 1 and 100}
}</pre></blockquote>

    An argspec takes one of two forms, depending on whether there's a default value or not:

    <ol>
    <li><blockquote><code>{<i>name</i>[:<i>flag</i>,<i>flag</i>,<i>flag</i>] <i>default</i>}</code></blockquote>
    <li><blockquote><code><i>name</i>[:<i>flag</i>,<i>flag</i>,<i>flag</i>]</code></blockquote>
    </ol>

    <p>
    
    If no default value is specified, the argument is considered required, but the empty string is permissible unless you 
    specify <code>:notnull</code>.  For all arguments, the filter <code>:nohtml</code> is applied by default.  If the arg
    is named <code>*.tmpfile</code>, the <code>tmpfile</code> filter is applied.

    <p>

    Possible flags are: 

    <blockquote>    

    <dl>

    <dt><b>trim</b>
    <dd>The value will be string trimmed.
    
    <dt><b>notnull</b>
    <dd>When set, will barf if the value is the empty string. 
    Checked after processing the <code>trim</code> flag. If <b>not</b> set,
    the empty string is <b>always</b> considered valid input, and <b>no other
    filters are processed for that particular value</b>. If it's an array or 
    multiple variable, the filters will still be applied for other values, though.

    <dt><b>optional</b>
    <dd>If there's a default value present,
    it's considered optional even without the flag. If a default is
    given, and the argument is present but blank, the default value will
    be used. Optional and no default value means the variable will not
    be set, if the argument is not present in the query string.

    <dt><b>multiple</b>
    <dd>
    If multiple is specified, the var
    will be set as a list of all the argument values
    (e.g. arg=val1&arg=val2 will turn into arg=[list val1 val2]).
    The defaults are filled in from left to right, so it can depend on
    values of arguments to its left.

    <dt><b>array</b>
    <dd>
    This syntax maps query variables into Tcl arrays. If you specify
    <code>customfield:array</code>, then query var <code>customfield.foo</code> will 
    translate into the Tcl array entry <code>$customfield(foo)</code>. In other words:
    whatever comes after the dot is used as the key into the array,
    or, more mathematically: <code>x.y=z => set x(y) z</code>.
    If you use dot or comma is part of your key (i.e., <code>y</code> above contains comma or dot),
    then you can easily <code>split</code> on it in your Tcl code.
    Remember that you can use any other flag or filter with array.

    <dt><b>verify</b>
    <dd>Will invoke <a href="/api-doc/proc-view?proc=ad_verify_signature"><code>ad_verify_signature</code></a>
    to verify the value of the variable, to make sure it's the value that was output by us, and haven't been tampered with.
    If you use <a href="/api-doc/proc-view?proc=export_form_vars"><code>export_form_vars -sign</code></a>
    or <a href="/api-doc/proc-view?proc=export_url_vars"><code>export_url_vars -sign</code></a> to export the 
    variable, use this flag to verify it. To verify a variable named <code>foo</code>, the verify flag 
    looks for a form variable named <code>foo:sig</code>. For a <code>:multiple</code>, it only expects one single 
    signature for the whole list. For <code>:array</code> it also expects one signature only, taken on the
    <code>[array get]</code> form of the array.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_date"><b>date</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the array validates as a date.
    Use this filter with :array to do automatic date filtering.  To use it, set up in your HTML form
    a call to \[ad_dateentrywidget varname\].  Then on the receiving page, specify the filter using
    <code>varname:array,date</code>.  If the date validates, there will be a variable set in your
    environment <code>varname</code> with four keys: <code>day, month, year,</code> and <code>date</code>.
    You can safely pass <code>$varname(date)</code> to Oracle.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_time"><b>time</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the array validates as a time in 
    am/pm format. That is that it has two fields: <code>time</code> and <code>ampm</code> that have 
    valid values. Use this filter with :array to do automoatic time filtering. To use it, set up 
    in you HTML form using \[ec_timeentrywidget varname\] or equivalent. Then on the processing page
    specify the filter using <code>varname:array,time</code>. If the time validates, there will be
    a variable set in your environment <code>varname</code> with five keys: <code>time, ampm,
    hours, minutes,</code> and <code>seconds</code>.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_time24"><b>time24</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the array validates as a time in 
    24hr format. That is that it has one field: <code>time</code> that has valid values. Use this
    filter with :array to do automoatic time filtering. To use it, set up in you HTML form using
    &lt;input type=text name=varname.time&gt;. Then on the processing page specify the filter using 
    <code>varname:array,time24</code>. If the time validates, there will be a variable set in your
    environment <code>varname</code> with four keys: <code>time, hours, minutes,</code> and
    <code>seconds</code>.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_integer"><b>integer</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value is integer, 
    and removed any leading zeros.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_naturalnum"><b>naturalnum</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value is a natural number, i.e.
    non-decimal numbers >= 0.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_range"><b>range</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value X is in range
    \[Y, Z\]. To use it say something like: <code>foo:(1|100)</code>

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_nohtml"><b>nohtml</b></a>
    <dd>Pluggable filter, installed by default, that disallows any and all html.
    
    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_html"><b>html</b></a>
    <dd>Pluggable filter, installed by default, that only allows certain, safe allowed tags to pass (see
    <a href="proc-view?proc=ad_html_security_check">ad_html_security_check</a>).
    The purpose of screening naughty html is to prevent users from uploading
    HTML with tags that hijack page formatting or execute malicious code on the users's computer.
    
    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_allhtml"><b>allhtml</b></a>
    <dd>Pluggable filter, installed by default, that allows any and all html.  Use of this filter
    is not reccomended, except for cases when the HTML will not be presented to the user or there is some
    other reason for overriding the site-wide control over naughty html.
    
    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_tmpfile"><b>tmpfile</b></a>
    <dd>Checks to see if the path and file specified by tmpfile are allowed on this system.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_sql_identifier"><b>sql_identifier</b></a> 
    <dd>Pluggable filter, installed by default, that makes sure the value is a valid SQL identifier.

    </dl>

    <a href="/api-doc/proc-search?query_string=ad_page_contract_filter_proc&search_type=Search&name_weight=5&param_weight=3&doc_weight=2">more filters...</a>

    </blockquote>

    <p>

    <b>Note</b> that there can be <em>no</em> spaces between name,
    colon, flags, commas, etc. The first space encountered denotes the 
    beginning of the default value. Also, variable names can't contain
    commas, colons or anything Tcl accepts as list element seperators 
    (space, tab, newline, possibly others)
    If more than one value is specified for something that's not 
    a multiple, a complaint will be thrown ("you supplied more than one value for foo").

    <p>

    There's an interface for enhancing ad_page_contract with <b>pluggable filters</b>, whose names 
    can be used in place of flags
    (see <a href="proc-view?proc=ad_page_contract_filter"><code>ad_page_contract_filter</code></a>). 
    There's also an interface for pluggable <b>filter rules</b>, which determine
    what filters are applied to arguments (see <a
    href="proc-view?proc=ad_page_contract_filter_rule"><code>ad_page_contract_filter_rule</code></a>).

    <p>
    
    Note on <strong>QQ-variables</strong>: Unlike the old <code>ad_page_variables</code>, 
    <code>ad_page_contract</code> does <strong>not</strong> set QQ-versions of variables.
    The QQ-versions (had each single-quote replaced by two single-quotes) were only necessary
    for building up SQL statements directly in a Tcl string. Now that we're using bind variables,
    the QQ-variables aren't necessary anymore, and thus, <code>ad_page_contract</code> doesn't waste
    time setting them.

    <h3>Default Values</h3>

    <strong>Default values</strong> are filled in from left to right (or top to
    bottom), so it can depend on the values or variables that comes
    before it, like in the example above. Default values are <strong>only used when
    the argument is not supplied</strong>, thus you can't use default values to override the 
    empty string. (This behavior has been questioned and may have to
    be changed at a later point.)
    Also, default values are <em>not</em> checked, even if you've specified
    flags and filters. If the argument has the <b><code>multiple</code></b> flag specified, 
    the default value is treated as a list. If the <b><code>array</code></b> flag is specified, we
    expect it to be in <code>array get</code> format, i.e. a list of <code>{ name value name value ... }</code>
    pairs. If both <b><code>multiple</code></b> and <b><code>array</code></b> are set, the <code>value</code> elements of the 
    before-mentioned <code>array get</code> format are treated as lists themselves.
 
    <h3>Errors Argument</h3>

    The <b><code>-errors</code></b> block defines custom error messages. The format is a list in <code>array get</code> format
    with alternating error-names and error texts. The error names can be <code>foo</code>, which 
    means it's thrown when the variable is not supplied. Or <code>foo:flag,flag,...</code>, which 
    means it'll get thrown whenever one of the flags fail. If you want the same error to be 
    thrown for both not supplying a var, and for a flag, you can say <code>foo<b>:,</b>flag,...</code>
    (a comma immediately after the colon).

    <h3>Validation Blocks</h3>

    The <b><code>-validate</code></b> is used to fully customized user input validation. The format is a list 
    of named chunks of code, for example:

    <pre>-validate {
    <i>name</i> {
        <i>code block</i>
    }
    <i>another_name</i> -requires { <i>argname</i>[:<i>filter-or-validation-block-name</i>,...] ... } {
        <i>code block</i>
    }
}</pre>
	

    The name is for use with the <code>-errors</code> block, and for use within the <code>-requires</code>
    argument of another validation block.
    The validation blocks will get executed after all flags and filters have been evaluated.
    The code chunk should perform some validation, and if it's unhappy it should call 
    <a href="proc-view?proc=ad_complain"><code>ad_complain</code></a>, <i>optionally</i> with an error message.
    If no error message is specified, the error should be declared in the <code>-errors</code> section.

    <p>

    Each validation block can also have a <b><fcode>-requires</code></b> switch, which takes a list of 
    validations that must already have been successfully passed, for the validation to get executed.
    The intent is that you want to provide as much feedback as possible at once, but you don't want 
    redundant feedback, like "foo must be an integer" <em>and</em> "foo must be in range 10 to 20".
    So a check for foo in range 10 to 20 would have a <code>-requires { foo:integer }</code> switch,
    to ensure that the check only gets executed if foo was sucessfully validated as an integer.

    <p>

    In the <code>-requires</code> argument, you can specify a list of (1) the
    name of an argument, which means that the argument must be supplied.
    Or (2) you can specify <code><i>argname</i>:<i>filter</i></code> or 
    <code><i>argname</i>:<i>validation_block</i></code> to say that a given filter, flag or 
    valdiation block must have been executed <em>and</em> satisfied for this validation block to get executed. 
    You can have as many requirements as you like.
    
    <p>

    @param docstring the documentation for your page; 
    will be parsed like ad_proc and ad_library.

    @param query the query arguments that this page accepts. The query
    argument takes form of a list of argument specs. See above.

    @param type the document type that this page will deliver. Use
    properties if the type is anonymous.

    @param properties what properties the resulting document will contain, in case
    you don't specify a predefined type.
    
    @author Lars Pind (lars@pinds.com)
    @author Yonatan Feldman (yon@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 16 June 2000
} {
    ad_complaints_init

    ####################
    #
    # Parse arguments
    #
    ####################


    if { [llength $args] == 0 } {
	set query [list]
    } else {
	
	set valid_args { validate errors return_errors properties }; 	# add type later

	# If the first arg isn't a switch, it should be the query
	if { [string index [lindex $args 0] 0] != "-" } {
	    set query [lindex $args 0]
	    set args [lrange $args 1 end]
	} else {
	    # otherwise, accept a -query argument
	    lappend valid_args query
	    set query [list]
	}
	
	ad_arg_parser $valid_args $args
    }

    if {[info exists type] && [info exists properties]} {
	return -code error "You can't have both a -type and a -properties argument with ad_page_contract"
    }

    ####################
    # 
    #   Check supplied query form and set up variables in caller's environment
    # 
    ####################
    #
    # These are the steps:
    # 1. go over the formal args, massaging it into an internal data structure that's easier to manipulate
    # 2. go over the form (actual args), match actual to formal args, apply filters
    # 3. go over the formal args again: defaulting, post filters, complain if required but not supplied
    # 4. execute the validation blocks
    #
    ####################


    ####################
    #
    # Step 1: Massage the query arg into some useful data structure.
    #
    ####################
    # BASIC STUFF:
    # list apc_formals                list of formals in the order specified by in the arguments
    # array apc_formal($name)         1 if there is a formal argument with that name
    # array apc_default_value($name)  the default value, if any
    # 
    # FILTERS:
    # array apc_internal_filter($name:$flag):        1 if the given flag is set, undefined
    # array apc_filters($name):                      contains a list of the filters to apply
    # array apc_post_filters($name):                 contains a list of the post filters to apply
    # array apc_filter_parameters($name:$flag:):      contains a list of the parameters for a filter
    #
    # DOCUMENTATION:
    # array apc_flags($name):         contains a list of the flags that apply
    #
    
    set apc_formals [list]
    array set apc_formal [list]
    array set apc_default_value [list]

    array set apc_internal_filter [list]
    array set apc_filters [list]
    array set apc_post_filters [list]
    array set apc_filter_parameters [list]

    array set apc_flags [list]

    foreach element $query {
	set element_len [llength $element]

	if { $element_len > 2 } {
	    return -code error "Argspec '$element' is invalid, because it contains more than two elements."
	}

	set arg_spec [lindex $element 0]

	if { ![regexp {^([^ \t:]+)(?::([a-zA-Z0-9_,(|)]*))?$} $arg_spec match name flags] } {
	    return -code error "Argspec '$arg_spec' doesn't have the right format. It must be var\[:flag\[,flag ...\]\]"
	}
	
	lappend apc_formals $name
        set apc_formal($name) 1
	     
	if { $element_len == 2 } {
	    set apc_default_value($name) [lindex $element 1]
	} 

	set pre_flag_list [split [string tolower $flags] ,]
	set flag_list [list]

	# find parameterized flags
	foreach flag $pre_flag_list {
	    set left_paren [string first "(" $flag]
	    if { $left_paren == -1 } {
		lappend flag_list $flag
	    } else {
		if { ![string equal [string index $flag end] ")"] } {
		    return -code error "Missing or misplaced end parenthesis for flag '$flag' on argument '$name'"
		}
		set flag_parameters [string range $flag [expr $left_paren + 1] [expr [string length $flag]-2]]
		set flag [string range $flag 0 [expr $left_paren - 1]]

		lappend flag_list $flag
		foreach flag_parameter [split $flag_parameters "|"] {
		    lappend apc_filter_parameters($name:$flag) $flag_parameter
		}
	    }
	}

	#
	# Apply filter rules
	#

	foreach filter_rule [nsv_array names ad_page_contract_filter_rules] { 
	    [ad_page_contract_filter_rule_proc $filter_rule] $name flag_list
	}

	# 
	# Sort the flag list according to priority
	#

	set flag_list_for_sorting [list]
	foreach flag $flag_list {
	    lappend flag_list_for_sorting [list [ad_page_contract_filter_priority $flag] $flag]
	}
	set flag_list_sorted [lsort -index 0 $flag_list_for_sorting]

	#
	# Split flag_list up into the different kinds, i.e. internal, filter (classic) or post_filter.
	#
	# apc_flags($name) is for documentation only.
	#

	set apc_flags($name) [list]
	set apc_filters($name) [list]
	set apc_post_filters($name) [list]

	foreach flag_entry $flag_list_sorted {
	    set flag [lindex $flag_entry 1]
	    lappend apc_flags($name) $flag
	    
	    switch [ad_page_contract_filter_type $flag] {
		internal {
		    set apc_internal_filter($name:$flag) 1
		}
		filter {
		    lappend apc_filters($name) $flag
		}
		post {
		    lappend apc_post_filters($name) $flag
		}
		default {
		    return -code error "Unrecognized flag or filter \"$flag\" specified for query argument $name"
		}
	    }
	}
    }

    ####################
    #
    # Documentation-gathering mode
    #
    ####################

    if { [api_page_documentation_mode_p] } {
	# Just gather documentation for this page

	ad_parse_documentation_string $docstring doc_elements

	# copy all the standard elements over
	foreach element { query type properties } {
	    if { [info exists $element] } {
		set doc_elements($element) [set $element]
	    }
	}
	# then the arrays
	foreach element { apc_default_value apc_flags } {
	    set doc_elements($element) [array get $element]
	}
	# then the array names
	set doc_elements(apc_arg_names) $apc_formals
	
	# figure out where the calling script is located, relative to the ACS root
	set root_dir [nsv_get acs_properties root_directory]
	set script [info script]
	set root_length [string length $root_dir]
	if { ![string compare $root_dir [string range $script 0 [expr { $root_length - 1 }]]] } {
	    set script [string range $script [expr { $root_length + 1 }] end]
	}

	error [array get doc_elements] "ad_page_contract documentation"
    }

    #
    # Page serving mode
    #

    ####################
    #
    # Parse -properties argument
    #
    ####################
    # This must happen even if the query (aka parameters, formals) is empty

    if { [info exists properties] } {
	upvar 1 __page_contract_property property
	array set property [doc_parse_property_string $properties]
    }

    # If there are no query arguments to process, we're done
    if { ![info exists query] || [empty_string_p $query] } {
	return
    }

    ####################
    #
    # Parse -validate block
    #
    ####################
    #
    # array apc_validation_blocks($name): an array of lists that contain the validation blocks
    #                                    the list will contain either 1 or 2 elements, a possible
    #                                    list of required completed filters/blocks and the code block
    #                                    for the validation block. Once the block has executed, this entry
    #                                    self destructs, i.e. unset apc_validation_blocks($name)

    array set apc_validation_blocks [list]

    if { ![info exists validate] } {
	set validate [list]
    }

    set validate_len [llength $validate]
    for { set i 0 } { $i < $validate_len } { incr i } {
	set name [lindex $validate $i]

	if { [string first : $name] != -1 } {
	    return -code error "Validation block names cannot contain colon"
	}
	if { [info exists apc_formal($name)] } {
	    return -code error "You can't name your validation blocks the same as a formal argument"
	}
	if { [info exists apc_validation_blocks($name)] } {
	    return -code error "You can't have two validation blocks named '$name'"
	}

	incr i
	if { [string index [lindex $validate $i] 0] == "-" } {
	    if { ![string equal [lindex $validate $i] -requires] } {
		return -code error "Valid switches are: -requires"
	    }
	    set requires [lindex $validate [incr i]]

	    foreach element $requires {
		if { [string first , $element] != -1 } {
		    return -code error "The -requires element \"$element\" has a comma in it."
		}
		set parts_v [split $element ":"]
		set parts_c [llength $parts_v]
		if { $parts_c > 2 }  {
		    return -code error "The -requires element \"$element\" has too many colons"
		}
		set req_filter [lindex $parts_v 1]
		if { [string equal $req_filter array] || [string equal $req_filter multiple] } {
		    return -code error "You can't require \"$req_name:$req_filter\" for block \"$name\"."
		}
	    }
	    incr i
	} else {
	    set requires [list]
	}
	set code [lindex $validate $i]
	set apc_validation_blocks($name) [list $requires $code]
    }

    ####################
    #
    # Parse -errors argument
    #
    ####################

    if { [info exists errors] } {
	ad_complaints_parse_error_strings $errors
    }

    ####################
    #
    # Step 2: Go through all the actual arguments supplied in the form
    # 
    ####################

    set form [ns_getform]
    
    if { [empty_string_p $form] } {
	set form_size 0
    } else {
	set form_size [ns_set size $form]
    }

    # This is the array in which we store the signature variables as we come across them
    # Whenever we see a variable named foo:sig, we record it here as apc_signatures(foo).
    array set apc_signatures [list]
	
    for { set form_counter_i 0 } { $form_counter_i < $form_size } { incr form_counter_i } {
	
	#
	# Map actual argument to formal argument ... only complication is from arrays
	#


	# The name of the argument passed in the form
	set actual_name [ns_set key $form $form_counter_i]

	# The name of the formal argument in the page
	set formal_name $actual_name

	# This will be var(key) for an array
	set variable_to_set var

	# This is the value	
	set actual_value [ns_set value $form $form_counter_i]

	# It may be a signature for another variable
	if { [regexp {^(.*):sig$} $actual_name match formal_name] } {
	    set apc_signatures($formal_name) $actual_value
	    # We're done with this variable
	    continue
	}
	
        # If there is no formal with this name, _or_ the formal that has this name is an array, 
        # in which case it can't be the right formal, since we'd have to have a dot and then the key
	if { ![info exists apc_formal($formal_name)] || [info exists apc_internal_filter($formal_name:array)] } {

	    # loop over all the occurrences of dot in the argument name
	    # and search for a variable spec with that name, e.g.
	    # foo.bar.greble can be interpreted as foo(bar.greble) or foo.bar(greble)
	    set found_p 0
	    set actual_name_v [split $actual_name "."]
	    set actual_name_c [expr { [llength $actual_name_v] - 1 }]
	    for { set i 0 } { $i < $actual_name_c } { incr i } {
		set formal_name [join [lrange $actual_name_v 0 $i] "."]
		if { [info exists apc_internal_filter($formal_name:array)] } {
		    set found_p 1
		    set variable_to_set var([join [lrange $actual_name_v [expr $i+1] end] "."])
		    break
		}
	    }
	    if { !$found_p } {
		# The user supplied a value for which we didn't have any arg_spec
		# It might be safest to fail completely in this case, but for now, 
		# we just ignore it and go on with the next arg
		continue
	    }
	}
	
	# Remember that we've found the spec so we don't complain that argument is missing
	ad_page_contract_set_validation_passed $formal_name

	#
	# Apply filters
	#

	if { [info exists apc_internal_filter($formal_name:trim)] } {
	    set actual_value [string trim $actual_value]
	    ad_page_contract_set_validation_passed $formal_name:trim
	}

	if { [empty_string_p $actual_value] } {
	    if { [info exists apc_internal_filter($formal_name:notnull)] } {
		ad_complain -key $formal_name:notnull "You must specify something for $formal_name"
		continue
	    } else { 
		ad_page_contract_set_validation_passed $formal_name:notnull
	    }
	} else {
	    global ad_page_contract_errorkeys ad_page_contract_validations_passed
	    set ad_page_contract_validations_passed($formal_name:notnull) 1

		foreach filter $apc_filters($formal_name) {
		    set ad_page_contract_errorkeys [concat $formal_name:$filter $ad_page_contract_errorkeys]
		    if { ![info exists apc_filter_parameters($formal_name:$filter)] } {
			set filter_ok_p [[ad_page_contract_filter_proc $filter] $formal_name actual_value]
		    } else {
			set filter_ok_p [[ad_page_contract_filter_proc $filter] $formal_name actual_value \
				$apc_filter_parameters($formal_name:$filter)]
		    }
		    set ad_page_contract_errorkeys [lrange $ad_page_contract_errorkeys 1 end]
		    
		    if { $filter_ok_p } {
			set ad_page_contract_validations_passed($formal_name:$filter) 1
		    } else {
			break
		    }
		}
	}

	#
	# Set the variable in the caller's environment
	#
	
	upvar 1 $formal_name var
	
	if { [info exists apc_internal_filter($formal_name:multiple)] } {
	    lappend $variable_to_set $actual_value
	} else {
	    if { [info exists $variable_to_set] } {
		ad_complain -key $formal_name:-doublevalue "You've supplied two values for '$formal_name'"
		continue
	    } else {
		set $variable_to_set $actual_value
	    }
	}
    }
    
    ####################
    # 
    # Step 3: Pass over each formal argument to make sure all the required
    # things are there, and setting defaults if they're provided, 
    # apply post filters, and validate signatures.
    #
    ####################

    foreach formal_name $apc_formals {
	
	upvar 1 $formal_name var
	
	if { [ad_page_contract_get_validation_passed_p $formal_name] } {
	    
	    if { [info exists apc_internal_filter($formal_name:verify)] } {
		if { ![info exists apc_internal_filter($formal_name:array)] } {
 		    # This is not an array, verify the variable
		    if { ![info exists apc_signatures($formal_name)] || \
			    ![ad_verify_signature $var $apc_signatures($formal_name)] } {
			ad_complain -key $formal_name:verify "The signature for the variable '$formal_name' was incorrect."
			continue
		    }
		} else {
		    # This is an array: verify the [array get] form of the array
		    if { ![info exists apc_signatures($formal_name)] || \
			    ![ad_verify_signature [array get var] $apc_signatures($formal_name)] } {
			ad_complain -key $formal_name:verify "The signature for the variable '$formal_name' was incorrect."
			continue
		    }
		}
	    }

	    # Apply post filters
	    if { [info exists var] } {
		foreach filter $apc_post_filters($formal_name) {
		    ad_complaints_with_key $formal_name:$filter {
			if { ![info exists apc_filter_parameters($formal_name:$filter)] } {
			    set filter_ok_p [[ad_page_contract_filter_proc $filter] $formal_name var]
			} else {
			    set filter_ok_p [[ad_page_contract_filter_proc $filter] $formal_name var $apc_filter_parameters($formal_name:$filter)]
			}
		    }
		    if { $filter_ok_p } {
			ad_page_contract_set_validation_passed $formal_name:$filter
		    } else { 
			break
		    }
		}
	    }
	    
	} else {
	    
	    # no value supplied for this arg spec
	    
	    if { [info exists apc_default_value($formal_name)] } {
		
		# Only use the default value if there has been no complaints so far
		# Why? Because if there are complaints, the page isn't going to serve anyway,
		# and because one default value may depend on another variable having a correct value.
		if { [ad_complaints_count] == 0 } {
		    # we need to set the default value
		    if { [info exists apc_internal_filter($formal_name:array)] } {
			array set var [uplevel subst \{$apc_default_value($formal_name)\}]
		    } else {
			set var [uplevel subst \{$apc_default_value($formal_name)\}]
		    }
		}
		
	    } elseif { ![info exists apc_internal_filter($formal_name:optional)] } {
		ad_complain -key $formal_name "You must supply a value for $formal_name"
	    }
	}
    }

    ####################
    #
    # Step 4: Execute validation blocks 
    #
    ####################

    set done_p 0
    global ad_page_contract_validations_passed ad_page_contract_errorkeys
    while { !$done_p } {

	set done_p 1
	foreach validation_name [array names apc_validation_blocks] {
	    set dependencies [lindex $apc_validation_blocks($validation_name) 0]
	    set code [lindex $apc_validation_blocks($validation_name) 1]

	    set dependencies_met_p 1
	    foreach dependency $dependencies {
		if { ![info exists ad_page_contract_validations_passed($dependency)] } {
		    set dependencies_met_p 0
		    break
		}
	    }

	    if { $dependencies_met_p } {

		# remove from validation blocks array, so we don't execute the same block twice
		unset apc_validation_blocks($validation_name)

		set no_complaints_before [ad_complaints_count]

		# Execute the validation block with an environment with a default error key set
		set ad_page_contract_errorkeys [concat $validation_name $ad_page_contract_errorkeys]
		set validation_ok_p [ad_page_contract_eval uplevel 1 $code]
		set ad_page_contract_errorkeys [lrange $ad_page_contract_errorkeys 1 end]

		if { [empty_string_p $validation_ok_p] || \
			(![string equal $validation_ok_p 1] && ![string equal $validation_ok_p 0])} {
		    set validation_ok_p [expr [ad_complaints_count] == $no_complaints_before]
		}
		
		if { $validation_ok_p } {
		    set ad_page_contract_validations_passed($validation_name) 1
		    # more stuff to process still
		    set done_p 0
		}
		    
	    }
	}
    }

    ####################
    #
    # Done. Spit out error, if any
    #
    ####################

    # Initialize the list of page variables for other scripts to use
    global ad_page_contract_variables
    set ad_page_contract_variables $apc_formals

    if { [ad_complaints_count] > 0 } {
	if { [info exists return_errors] } {
	    upvar 1 $return_errors error_list
	    set error_list [ad_complaints_get_list]
	} else {
	    ad_return_complaint [ad_complaints_count] "<li>[join [ad_complaints_get_list] "\n<li>"]"
	    ad_script_abort
	}
    }
}

ad_proc -public ad_page_contract_get_variables { } {
    Returns a list of all the formal variables specified in
    ad_page_contract. If no variables have been specified, returns an
    empty list.  
} {
    global ad_page_contract_variables
    if { [exists_and_not_null ad_page_contract_variables] } {
	return $ad_page_contract_variables
    } 
    return [list]
}

####################
#
# Filter subsystem
#
####################
#
# ad_page_contract_filters($flag) = [list $type $priority $proc_name $doc_string [info script] $parameterized_p]
#
# ad_page_contract_mutex(filters) = mutex
#
# types are: internal, filter, post
#

if { [apm_first_time_loading_p] } {

    nsv_array set ad_page_contract_filters {
	multiple  {internal 0 "" "" "" 0}
	array     {internal 0 "" "" "" 0}
	optional  {internal 0 "" "" "" 0}
	trim      {internal 0 "" "" "" 0}
        notnull   {internal 0 "" "" "" 0}
	verify	  {internal 0 "" "" "" 0}
    }
	
    nsv_array set ad_page_contract_filter_rules [list]

    nsv_set ad_page_contract_mutex filters [ns_mutex create]
    nsv_set ad_page_contract_mutex filter_rules [ns_mutex create]

}

ad_proc -public ad_page_contract_filter { 
    {-type filter}
    {-priority 1000}
    name
    proc_args
    doc_string
    body 
} {
    Declare a filter to be available for use in ad_page_contract.
    <p>
    Here's an example of how to declare a filter:

    <pre>
    ad_page_contract_filter integer { name value } {
	Checks whether the value is a valid integer, and removes any leading zeros so as 
	not to confuse Tcl into thinking it's octal
    } {
	if { ![regexp {^[0-9]+$} $value] } {
	    ad_complain "Value is not an integer"
	    return 0
	}
	# trim leading zeros, so as not to confuse Tcl
	set value [string trimleft $value "0"]
	if { [empty_string_p $value] } {
	    # but not all of the zeros
	    set value "0"
	}
	return 1
    }
    </pre>
    
    After the filter has been declared, it can be used as a flag in <code>ad_page_contract</code>, e.g. 
    <pre>
    ad_page_contract {
	foo:integer
    } {}
    </pre>

    <b>Note</b> that there's only one global namespace for names. At some point,
    we might add package-local filters, but we don't have it yet.

    <p>

    The filter proc <b>must</b> return either 1 if it accepts the value or 0 if it rejects it.
    Any problem with the value is reported using <b><code>ad_complain</code></b> (see documentation 
    for this). <b>Note:</b> Any modifications you make to value from inside your code block <b>will modify 
    the actual value being set in the page.</b>

    <p>

    There are two types of filters. They differ in scope for variables that are <b>multiple</b> or <b>array</b>.
    The standard type of filter (<b>filter classic</b>) is invoked on each individual value before it's being put into the 
    list or the array. A <b>post filter</b> is invoked after all values have been collected, and is invoked on the
    list or array as a whole.

    <p>
    
    @param type The type of filter; i.e. <code>filter</code> or <code>post</code>. Default is <code>filter</code>.

    @param name The name of the flag as used in <code>ad_page_contract</code>

    @param proc_args the arguments to your filter. The filter must
    take three arguments, <code>name</code>, <code>value</code>, and <code>parameters</code>, although you can name them
    any way you want. The first will be set to the name of the variable, the second will <b>be upvar'd</b> to the value,
    so that any change you make to the value will be reflected in the value ultimately being set in the page's
    environment, and the third is a list of arguments to the filter. This third argument can have multiple parameters
    split by <code>|</code> with no spaces or any other characters. Something like <code>foo:range(3|5)</code>

    @param body The body is a procedure body that performs the
    filtering. It'll automatically have one argument named
    <code>value</code> set, and it must either return the possibly
    transformed value, or throw an error. The error message will
    be displayed to the user.
    
    @param doc_string Standard documentation-string. Tell other programmers what your filter does.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {

    if { ![string is wordchar $name] || [empty_string_p $name] } {
	return -code error "Flag name must be a valid identifier"
    }
    if { ![string equal [string tolower $name] $name] } {
	return -code error "Flag names must be all lowercase"
    }
    if { ![string match $type filter] && ![string match $type post] } {
	return -code error "Filter type must be 'filter' or 'post'"
    }

    set proc_args_len [llength $proc_args]

    switch $proc_args_len {
	2 {
	    set parameterized_p 0
	} 
	3 {
	    set parameterized_p 1
	} 
	default {
	    return -code error "Invalid number of arguments declared for the proc. Should be: the argument name and the value and possibly parameters"
	}
    }

    set script [info script]
    set proc_name ad_page_contract_filter_proc_$name

    #
    # Register the filter
    #

    set mutex [nsv_get ad_page_contract_mutex filters]
    ns_mutex lock $mutex

    set prior_type [ad_page_contract_filter_type $name]

    if { [string equal $prior_type internal] } {
	ns_mutex unlock $mutex
	return -code error "The flag name \"$name\" is reserved for ad_page_contract"
    } elseif { ![empty_string_p $prior_type] } {
	set prior_script [ad_page_contract_filter_script $name]
	if { ![string equal $prior_script $script] } {
	    ns_log Warning "Multiple definitions of ad_page_contract filter \"$name\" in $script and $prior_script"
	}
    }

    nsv_set ad_page_contract_filters $name [list $type $proc_name $doc_string $script $priority $parameterized_p]
    ns_mutex unlock $mutex

    #
    # Declare the proc
    #

    # this may look complicated, but it's really pretty simple: 
    # If you declare a filter like this: ad_page_contract_filter foo { name value } { ... }
    # it turns into this proc:
    # ad_proc ad_page_contract_filter_proc_foo { name value_varname } { upvar $value_varname value ; ... }
    # so that when the filter proc is passed the name of a variable, the body of the proc
    # will have access to that variable as if the value had been passed.

    set doc_string "Custom filter for use in <a href=\"proc-view?proc=ad_page_contract\"><code>ad_page_contract</code></a>.<p>$doc_string"
    
    set arg1 [lindex $proc_args 1]
    set arg1varname "${arg1}_varname"
    set proc_args [lreplace $proc_args 1 1 $arg1varname] 

    ad_proc $proc_name $proc_args $doc_string "upvar \$$arg1varname $arg1\n$body"
}

ad_proc ad_page_contract_filter_type { filter } {
    Returns the type of proc that executes the given ad_page_contract filter, 
    or the empty string if the filter is not defined.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { [nsv_exists ad_page_contract_filters $filter] } {
	return [lindex [nsv_get ad_page_contract_filters $filter] 0]
    } else {
	return {}
    }
}

ad_proc ad_page_contract_filter_get_proc { filter } {
    Returns the proc that executes the given ad_page_contract filter.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return [lindex [nsv_get ad_page_contract_filters $filter] 1]
}

ad_proc ad_page_contract_filter_script { filter } {
    Returns the script in which the given ad_page_contract filter, 
    was defined.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return [lindex [nsv_get ad_page_contract_filters $filter] 3]
}

ad_proc ad_page_contract_filter_priority { filter } {
    Returns the priority of proc that executes the given ad_page_contract filter.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return [lindex [nsv_get ad_page_contract_filters $filter] 4]
}

ad_proc ad_page_contract_filter_parameterized_p { filter } {
    Returns whether the filter takes a parameter or not.

    @author Lars Pind (lars@pinds.com)
    @creation-date 7 September 2000
} {
    return [lindex [nsv_get ad_page_contract_filters $filter] 5]
}

ad_proc ad_page_contract_filter_invoke { filter name value_varname {parameters ""}} {
    Invokes a filter on the argument and returns the result (1 or 0).
    The value may be modified during the invocation of the filter.

    @param filter the name of the filter to invoke
    @param name the logical name of the variable to filter
    @param value_varname the name of the variable holding the value to be filtered.
    @param parameters a list of parameters to pass on to the filter. Whereas when a parameterized filter is used
    in ad_page_contract, the parameters are separated by the pipe (|)
    symbol, here they must be a standard Tcl list.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    upvar $value_varname value
    if { ![ad_page_contract_filter_parameterized_p $filter] } {
	set filter_result [[ad_page_contract_filter_get_proc $filter] $name value]
    } else {
	set filter_result [[ad_page_contract_filter_get_proc $filter] $name value $parameters]
    }
    ad_page_contract_set_validation_passed $name $filter $filter_result
    return $filter_result
}

####################
#
# Filter rules
#
####################

#
# ad_page_contract_filter_rules($name) = [list $proc_name $doc_string [info script]]
#
# ad_page_contract_mutex(filter_rules) = mutex
#

ad_proc ad_page_contract_filter_rule {
    name
    proc_args
    doc_string
    body
} { 
    A filter rule determines what filters are applied to a given value. The code is passed the 
    name of the formal argument and the list of filters currently being applied, and should 
    on that basis modify the list of filters to suit its needs. Usually a filter rule will add
    a certain filter, unless some list of filters are already present. 

    <p>
    
    Unlike the filters themselves (registered with <code>ad_page_contract_filter</code>, all rules 
    are always applied to all formal arguments of all pages.

    @param name filter rules must be named. The name isn't referred to anywhere.
    
    @param proc_args the filter rule proc must take two arguments, <code>name</code> and <code>filters</code>, 
    although you can name them as you like. The first will be set to the name of the formal argument,
    the second will <b>be upvar'd</b> to the list of filters, so that any modifications you make to this list
    are reflected in the actual list of filters being applied.

    @param doc_string let other programmers know what your filter rule does.

    @param body the code to manipulate the filter list.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { [llength $proc_args] != 2 } {
	return -code error "The proc must accept two  arguments, the name of the variable and a list of filters"
    }

    set script [info script]
    set proc_name ad_page_contract_filter_rule_proc_$name

    set mutex [nsv_get ad_page_contract_mutex filter_rules]
    ns_mutex lock $mutex

    if { [nsv_exists ad_page_contract_filter_rules $name] } {
	set prior_script [ad_page_contract_filter_rule_script $name]
	if { ![string equal $script $prior_script] } {
	    ns_log Warning "Multiple definitions of the ad_page_contract_filter_rule \"$name\" in $script and $prior_script"
	}
    }

    nsv_set ad_page_contract_filter_rules $name [list $proc_name $doc_string $script]
    ns_mutex unlock $mutex

    # same trick as ad_page_contract_filter does.

    set arg0 [lindex $proc_args 0]
    set arg1 [lindex $proc_args 1]
    ad_proc $proc_name [list $arg0 ${arg1}_varname] $doc_string "upvar \$${arg1}_varname $arg1\n$body"
}

ad_proc ad_page_contract_filter_rule_proc { filter } {
    Returns the proc that executes the given ad_page_contract default-filter.
} {
    return [lindex [nsv_get ad_page_contract_filter_rules $filter] 0]
}

ad_proc ad_page_contract_filter_rule_script { filter } {
    Returns the proc that executes the given ad_page_contract default-filter.
} {
    return [lindex [nsv_get ad_page_contract_filter_rules $filter] 2]
}

####################
#
# Declare standard filters
#
####################

ad_page_contract_filter integer { name value } {
    Checks whether the value is a valid integer, and removes any leading zeros so as 
    not to confuse Tcl into thinking it's octal. Allows negative numbers.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { ![regexp {^(-)?(0*)(([1-9][0-9]*|0))$} $value match sign zeros value] } {
	ad_complain "$name is not an integer"
	return 0
    }
    # Trim the value for any leading zeros
    set value $sign$value
    return 1
}

ad_page_contract_filter naturalnum { name value } {
    Checks whether the value is a valid integer >= 0, 
    and removes any leading zeros so as 
    not to confuse Tcl into thinking it's octal.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { ![regexp {^(0*)(([1-9][0-9]*|0))$} $value match zeros value] } {
	ad_complain "$name is not a natural number, that is an integer greater than or equal to 0."
	return 0
    }
    return 1
}

ad_page_contract_filter range { name value range } {
    Makes sure the value X is in range
    [Y, Z]. To use it say something like: <code>foo:(1|100)</code>

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date August 18, 2000
} {
    if { [lindex $range 0] < [lindex $range 1] } {
	set min [lindex $range 0]
	set max [lindex $range 1]
    } else {
	set min [lindex $range 1]
	set max [lindex $range 0]
    }
    if { $value < $min || $value > $max } {
	ad_complain "$name should be between $min and $max"
	return 0
    }
    return 1
}

ad_page_contract_filter sql_identifier { name value } {
    Checks whether the value is a valid SQL identifier
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {		
    if { ![string is wordchar $value] } {
	ad_complain "$name is not a valid SQL identifier"
	return 0 
    } 
    return 1
}

ad_page_contract_filter allhtml { name value } {
    Allows any html tags (a no-op filter)
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return 1
}

ad_page_contract_filter nohtml { name value } {
    Doesn't allow any HTML to pass through.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { [string first < $value] >= 0 } {
	ad_complain "Value for $name contains HTML tags"
	return 0
    }
    return 1
}

ad_page_contract_filter html { name value } {
    Checks whether the value contains naughty HTML
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    set naughty_prompt [ad_html_security_check $value]
    if { ![empty_string_p $naughty_prompt] } {
	ad_complain $naughty_prompt
	return 0
    }
    return 1
}

ad_page_contract_filter tmpfile { name value } {
    Checks to see that the tmpfile path is allowed on the system
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} { 
    # ensure no .. in the path
    ns_normalizepath $value
    
    # check to make sure path is to an authorized directory
    set tmpdir_list [ad_parameter_all_values_as_list TmpDir]
    if [empty_string_p $tmpdir_list] {
	set tmpdir_list [list "/var/tmp" "/tmp"]
    }
    
    foreach tmpdir $tmpdir_list {
	if { [string match "$tmpdir*" $value] } {
	    return 1
	}
    }
    
    ad_complain "You specified a path to a file that is not allowed on the system."
    ns_log Warning "ad_page_contract_filter tmpfile: Tmp-dir not allowed on system: ${name}=$value. You may want to add this to the TmpDir parameter in your server startup file."
    return 0
}

ad_page_contract_filter -type post date { name date } {
    Makes sure the value validates as a date. 
    Use this filter with :array to do automatic date filtering.  
    
    <p>

    To use it, set up in your HTML form
    a call to \[ad_dateentrywidget varname\].  Then on the receiving page, specify the filter using
    <code>varname:array,date</code>.  If the date validates, there will be a variable set in your
    environment <code>varname</code> with four keys: <code>day, month, year,</code> and <code>date</code>.
    You can safely pass <code>$varname(date)</code> to Oracle.

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date 25 July 2000
} {
    foreach date_element { day month year } {
	if { ![info exists date($date_element)] } {
	    ad_complain "Invalid date: $date_element is missing"
	    return 0
	}
    }
  
    # check if all elements are blank
    if { [empty_string_p "$date(day)$date(month)$date(year)"] } {
	set date(date) {}
	return 1
    } 

    foreach date_element { day year } {
	if { ![regexp {^(0*)(([1-9][0-9]*|0))$} $date($date_element) match zeros real_value] } {
	    ad_complain "Invalid date: $date_element is not a natural number"
	    return 0
	}
	set date($date_element) $real_value
    }

    if { ![empty_string_p $date(year)] && [string length $date(year)] != 4 } {
	ad_complain "Invalid date: The year must contain 4 digits."
	return 0
    } 

    if { [regexp {^(0*)(([1-9][0-9]*|0))$} $date(month) match zeros real_value] } {
	set date(month) $real_value
    } else {
	set date(month) [expr [lsearch [nsv_get _nsdb months] $date(month)] + 1]
    }

    if {
	[string match "" $date(month)] \
	    || [string match "" $date(day)] \
	    || [string match "" $date(year)] \
	    || $date(month) < 1 || $date(month) > 12 \
	    || $date(day) < 1 || $date(day) > 31 \
	    || $date(year) < 1 \
	    || ($date(month) == 2 && $date(day) > 29) \
	    || (($date(year) % 4) != 0 && $date(month) == 2 && $date(day) > 28) \
	    || ($date(month) == 4 && $date(day) > 30) \
	    || ($date(month) == 6 && $date(day) > 30) \
	    || ($date(month) == 9 && $date(day) > 30) \
	    || ($date(month) == 11 && $date(day) > 30)
    } {
	ad_complain "Invalid date: $date(month) $date(day) $date(year)"
	return 0
    }

    set date(date) [format "%04d-%02d-%02d" $date(year) $date(month) $date(day)]
    return 1
}

ad_page_contract_filter -type post time { name time } {
    Makes sure the array validates as a time in 
    am/pm format. That is that it has two fields: <code>time</code> and <code>ampm</code> that have 
    valid values. Use this filter with :array to do automoatic time filtering. 

    <p>

    To use it, set up 
    in you HTML form using \[ec_timeentrywidget varname\] or equivalent. Then on the processing page
    specify the filter using <code>varname:array,time</code>. If the time validates, there will be
    a variable set in your environment <code>varname</code> with five keys: <code>time, ampm,
    hours, minutes,</code> and <code>seconds</code>.

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date 25 July 2000
} {
    foreach time_element { time ampm } {
	if { ![info exists time($time_element)] } {
	    ad_complain "Invalid time: $time_element is missing"
	    return 0
	}
    }
  
    # check if all elements are blank
    if { [empty_string_p "$time(time)$time(ampm)"] } {
	return 1
    } 

    set time_element_values [split $time(time) ":"]
    if { [llength $time_element_values] != 3 } {
	ad_complain "Invalid time: $time(time) is in invalid format"
	return 0
    }

    set time_element_names [list hours minutes seconds]

    for { set i 0 } { $i < 3 } { incr i } {
	array set time [list [lindex $time_element_names $i] [lindex $time_element_values $i]]
    }

    if {
	[string match "" $time(hours)] \
	    || [string match "" $time(minutes)] \
	    || [string match "" $time(seconds)] \
	    || (![string equal -nocase "pm" $time(ampm)] && ![string equal -nocase "am" $time(ampm)])
	    || $time(hours) < 1 || $time(hours) > 12 \
	    || $time(minutes) < 0 || $time(minutes) > 59 \
	    || $time(seconds) < 0 || $time(seconds) > 59
    } {
	ad_complain "Invalid time: $time(time) $time(ampm)"
	return 0
    }

    return 1
}

ad_page_contract_filter -type post time24 { name time } {
    Makes sure the array validates as a time in 
    24hr format. That is that it has one field: <code>time</code> that has valid values. Use this
    filter with :array to do automoatic time filtering. 

    <p>

    To use it, set up in you HTML form using
    &lt;input type=text name=varname.time&gt;. Then on the processing page specify the filter using 
    <code>varname:array,time24</code>. If the time validates, there will be a variable set in your
    environment <code>varname</code> with four keys: <code>time, hours, minutes,</code> and
    <code>seconds</code>.

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date 25 July 2000
} {
    if { ![info exists time(time)] } {
	ad_complain "Invalid time: time is missing"
	return 0
    }
  
    # check if all elements are blank
    if { [empty_string_p "$time(time)"] } {
	return 1
    } 

    set time_element_values [split $time(time) ":"]
    if { [llength $time_element_values] != 3 } {
	ad_complain "Invalid time: $time(time) is in invalid format"
	return 0
    }

    set time_element_names [list hours minutes seconds]

    for { set i 0 } { $i < 3 } { incr i } {
	array set time [list [lindex $time_element_names $i] [lindex $time_element_values $i]]
    }

    if {
	[string match "" $time(hours)] \
	    || [string match "" $time(minutes)] \
	    || [string match "" $time(seconds)] \
	    || $time(hours) < 0 || $time(hours) > 23 \
	    || $time(minutes) < 0 || $time(minutes) > 59 \
	    || $time(seconds) < 0 || $time(seconds) > 59
    } {
	ad_complain "Invalid time: $time(time)"
	return 0
    }

    return 1
}





ad_page_contract_filter string_length_range { name value range} {
    Checks whether the string is within the specified range, inclusive

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date August 2000
} {
    if { [string length $value] < [lindex $range 0] } {
	ad_complain "$name is too short.  Please enter a value of at least [lindex $range 0] characters long. The value you entered was [string length $value] characters long."
	return 0
    } elseif { [string length $value] > [lindex $range 1] } {
	ad_complain "$name is too long.  Please enter a value of at most [lindex $range 1] characters long. The value you entered was [string length $value] characters long."
	return 0
    }
    return 1
}

ad_page_contract_filter string_length { name value length} {
    Checks whether the string is less or greater than the minimum or
    maximum length specified, inclusive
    e.g.address_1:notnull,string_length(max|100) will test address_1 for
    maximum length of 100.

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date August 2000
} {
    if { [lindex $length 0] == "min" } {
	if { [string length $value] < [lindex $length 1] } {
	    ad_complain "$name is too short.  Please enter a value of at least [lindex $length 1] characters long. The value you entered was [string length $value] characters long."
	    return 0
	}
    } else {
	if { [string length $value] > [lindex $length 1] } {
	    ad_complain "$name is too long.  Please enter a value of at most [lindex $length 1] characters long. The value you entered was [string length $value] characters long."
	    return 0
	}
    }
    return 1
}

ad_page_contract_filter email { name value } {
    Checks whether the value is a valid email address (stolen from
    philg_email_valid_p)

    @author Philip Greenspun (philip@mit.edu)
    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date 22 August 20000
} {
    set valid_p [regexp "^\[^@\t ]+@\[^@.\t]+(\\.\[^@.\n ]+)+$" $value]
    if { !$valid_p } {
	ad_complain "$name does not appear to be a valid email address."
	return 0
    }
    return 1
}

ad_page_contract_filter float { name value } {
    Checks to make sure that the value in question is a valid number,
    possibly with a decimal point
    - randyb took this from the ACS dev bboard

    @author Steven Pulito (stevenp@seas.upenn.edu)
    @creation-date 22 August 2000
} {
    # remove the first decimal point, the theory being that
    # at this point a valid float will pass an integer test
    regsub {\.} $value "" value_to_be_tested

    if { ![regexp {^[0-9]+$} $value_to_be_tested] } {
	ad_complain "Value is not an decimal number."
	return 0
    }
    # trim leading zeros, so as not to confuse Tcl
    set value [string trimleft $value "0"]
    if { [empty_string_p $value] } {
	# but not all of the zeros
	set value "0"
    }
    return 1
}

ad_page_contract_filter usphone { name value } {
    Checks whether the value is more or less a valid US phone number with
    the area code.
    Exact filter is XXX-XXX-XXXX

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date 22 August 2000
} {
    if {![empty_string_p [string trim $value]] && ![regexp {[1-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]} $value]} {
	ad_complain "$name does not appear to be a valid US phone number."
	return 0
    }
    return 1
}

ad_page_contract_filter boolean { name value } {
    Checks whether the value is boolean (1 or 0) or predicate (t or f)
    or otherwise
    a 2 state value (true or false, y or n, yes or no)

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date 23 August 2000
} {

    set lcase_value [string tolower $value]
    if {[string match $value "0"] || \
	    [string match $value "1"] || \
	    [string match $lcase_value "f"] || \
	    [string match $lcase_value "t"] || \
	    [string match $lcase_value "true"] || \
	    [string match $lcase_value "false"] || \
	    [string match $lcase_value "y"] || \
	    [string match $lcase_value "n"] || \
	    [string match $lcase_value "yes"] || \
	    [string match $lcase_value "no"] } {
	return 1
    } else {
	ad_complain "$name does not appear to be a boolean value."
	return 0
    }
}









####################
# 
# Standard filter rules
#
####################

ad_page_contract_filter_rule html { name filters } {
    Makes sure the filter nohtml gets applied, unless some other html filter (html or allhtml) 
    is already specified.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    foreach name { nohtml html allhtml integer naturalnum } {
	if { [lsearch -exact $filters $name] != -1 } {
	    return
	}
    }
    lappend filters nohtml
}

ad_page_contract_filter_rule tmpfile { name filters } {
    Makes sure the tmpfile filter gets applied for all vars named *.tmpfile.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { [string match "*tmpfile" $name] && [lsearch -exact $filters tmpfile] == -1 } {
	lappend filters tmpfile
    }
}
