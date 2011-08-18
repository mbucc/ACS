#
# /www/education/subject/admin/user-list.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com
#
# this page allows the person to select a user to lead a class
#

ad_page_variables {
    begin
    end
    {order_by ""}
    {target_url class-add.tcl}
    {param_list ""}
    {browse_type ""}
    lastletter
    type
}


# param_list should be any variables that need to be passed on
# to the next page.  These variables should have already been
# url encoded.  So, the calling page should have a line that looks like
# set param_list [ns_urlencode var1 var2 ...] and then
# [export_url_vars $param_list]


set db [ns_db gethandle]

if {![info exists order_by] || [empty_string_p $order_by]} {
    set order_by name
}

if {[string compare [string tolower $browse_type] select_instructor] == 0} {
    set begin_header "Select an Instructor/Moderator for the Class"
    set nav_bar_value "Select Instructor"
    set instructions "To select a user as the instructor, please click on their name."
    } else {
    set begin_header "Site Wide Users Search Results"
    set nav_bar_value "Site Wide Users"
    set instructions "To view information about a user, simply click on their name."
}


#check the input
set exception_count 0 
set exception_text ""

if {[empty_string_p $begin] } {
    incr exception_count
    append exception_text "<li>You must have a starting letter\n"
}

if {[empty_string_p $end] } {
    incr exception_count
    append exception_text "<li>You must have a stopping letter\n"
}

if {[empty_string_p $type] } {
    incr exception_count
    append exception_text "<li>You must provide a type\n"
}

if {[empty_string_p $lastletter] } {
    incr exception_count
    append exception_text "<li>You must provide a last letter\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    # terminate execution of this thread (a goto!)
    return
}




if { [string compare [string tolower $begin] a] == 0 && [string compare [string tolower $end] z] == 0 } {
    set header All
    set sql_suffix "where user_id > 2"
} else {
    #This code assumes that the variable End is the correct case!!!
    if {[string compare [string tolower $type] lastname] == 0} {
	set header "Last Names $begin through $lastletter"
	set sql_suffix "where upper('$begin') < upper(last_name)
                    and '$end' > upper(last_name)
                       and user_id > 2"
    } else {
	set header "Emails $begin through $lastletter"
	set sql_suffix "where upper('$begin') < upper(email)
                    and '$end' > upper(email)
                    and user_id > 2"
    }
}




set return_string "

[ad_header "Add a Class @ [ad_system_name]"]

<h2>$begin_header - $header </h2>

[ad_context_bar_ws [list "../" "Subjects"] [list "" "Subject Administration"] "Add a Class"]


<hr>
"

set export_vars [export_url_vars begin end type lastletter param_list]

set count 0

if {[string compare $order_by name] == 0} {
    set sql_order_by " lower(last_name), lower(first_names) "
    append return_string "<a href=\"user-list.tcl?order_by=email&[export_url_vars target_url browse_type]&$export_vars\">
    sort by email address</a><ul>"
} else {
    set sql_order_by " lower(email) "
    append return_string "<a href=\"user-list.tcl?l[export_url_vars target_url browse_type]&order_by=name&$export_vars\">
    sort by last name</a><ul>"
}

#get only users that are affiliated with the company user group
set sql_query "select users.user_id, 
                       first_names, 
                       last_name,
                       email
                  from users
                       $sql_suffix
                       order by $sql_order_by"


set selection [ns_db select $db $sql_query]

set count 0
while { [ns_db getrow $db $selection] } {
    incr count
    set_variables_after_query
    append return_string "<li><a href=\"$target_url?user_id=$user_id&$param_list\">$last_name, $first_names ($email)</a> $target_url"
}

if { $count == 0 } {
    append return_string "</ul>You do not currently have any users meeting the requirements."
} else {
    append return_string "</ul>$instructions"
}


append return_string "
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string






