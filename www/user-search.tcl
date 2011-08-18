# $Id: user-search.tcl,v 3.1 2000/02/20 10:50:01 ron Exp $
# Reusable page for searching for a user by email or last_name.
# Returns to "target" with user_id_from_search, first_names_from_search,
# last_name_from_search, and email_from_search, and passing along all
# form variables listed in "passthrough".


set_the_usual_form_variables
# email or last_name (search strings)
# target (URL to return to)
# passthrough (form variables to pass along from caller)
# custom_title (if you're doing a passthrough, 
# this title can help inform users what the search was for
# limit_to_users_in_group_id (optional argument that limits our search to users in the specified group id.
#   (Note that we allow limit_to_users_in_group_id to be a comma separated list... to allow searches within 
#    multiple groups) 


# Check input.
set errors ""
set exception_count 0

if { (![info exists email] || $email == "") && (![info exists last_name] || $last_name == "") } {
    incr exception_count
    append errors "<li>You must specify either an email address or last name to search for.\n"
}

if { [info exists email] && [info exists last_name] && $email != "" && $last_name != "" } {
    incr exception_count
    append errors "<li>You can only specify either email or last name, not both.\n"
}

if { ![info exists target] || $target == "" } {
    incr exception_count
    append errors "<li>Target was not specified. This shouldn't have happened,
please contact the <a href=\"mailto:[ad_host_administrator]\">administrator</a>
and let them know what happened.\n"
}

if { $errors != "" } {
    ad_return_complaint $exception_count $errors
    return
}

if { [info exists email] && $email != "" } {
    set search_text "email \"$email\""
    set search_clause "lower(email) like '%[string tolower $QQemail]%'"
} else {
    set search_text "last name \"$last_name\""
    set search_clause "lower(last_name) like '%[string tolower $QQlast_name]%'"
}


if { ![info exists passthrough] } {
    set passthrough ""
}
lappend passthrough user_id_from_search first_names_from_search last_name_from_search email_from_search

if { ![info exists custom_title] } {
	set display_title "Member Search"
} else {
	set display_title $custom_title
}

if { [exists_and_not_null limit_to_users_in_group_id] } {
set query "select u.user_id as user_id_from_search, 
  u.first_names as first_names_from_search, u.last_name as last_name_from_search,
  u.email as email_from_search, u.user_state
from users u, user_group_map ugm
where u.user_id=ugm.user_id
and ugm.group_id in ($limit_to_users_in_group_id)
and $search_clause"

} else {
set query "select user_id as user_id_from_search, 
  first_names as first_names_from_search, last_name as last_name_from_search,
  email as email_from_search, user_state
from users
where $search_clause"
}

set db [ns_db gethandle]

if { [exists_and_not_null limit_to_users_in_group_id] && ![regexp {[^0-9]} $limit_to_users_in_group_id] } {
    append display_title " in [database_to_tcl_string $db "select group_name from user_groups where group_id=$limit_to_users_in_group_id"]"
}

set selection [ns_db select $db $query]

ReturnHeaders

ns_write "[ad_header $display_title]
<h2>$display_title</h2>
for $search_text
<hr>
<ul>
"

set i 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    
    with_catch errmsg {
	set exported_variables [list]
	foreach var $passthrough {
	    ns_log Notice "var: $var"
	    lappend exported_variables [export_url_vars $var]
	}
	ns_write "<li><a href=\"$target?[join $exported_variables "&"]\">$first_names_from_search $last_name_from_search ($email_from_search)</a>\n"
    } {
	ns_write "<li>$errmsg\n"
    }
    incr i
}

if { $i == 0 } {
    ns_write "<li>No members found.\n"
}

ns_write "</ul>
[ad_footer]
"

