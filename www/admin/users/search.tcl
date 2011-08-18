# admin/users/search.tcl
#
# Reusable page for searching for a user by email or last_name.
# Returns to "target" with user_id_from_search, first_names_from_search,
# last_name_from_search, and email_from_search, and passing along all
# form variables listed in "passthrough".
#
# $Id: search.tcl,v 3.4 2000/03/09 00:01:36 scott Exp $
# -----------------------------------------------------------------------------


set_the_usual_form_variables
# email or last_name (search strings)
# also accept "keyword" (for looking through both)
# target (URL to return to)
# passthrough (form variables to pass along from caller)
# limit_to_users_in_group_id (optional argument that limits our search to users in the specified group id.
#   (Note that we allow limit_to_users_in_group_id to be a comma separated list... to allow searches within 
#    multiple groups) 

# Check input.
set exception_count 0
set exception_text ""

if [info exists keyword] {
    # this is an administrator 
    if { [empty_string_p $keyword] } {
	incr exception_count
	append exception_text "<li>You forgot to type a search string!\n"
    }
} else {
    # from one of the user pages
    if { (![info exists email] || $email == "") && (![info exists last_name] || $last_name == "") } {
	incr exception_count
	append exception_text "<li>You must specify either an email address or last name to search for.\n"
    }

    if { [info exists email] && [info exists last_name] && $email != "" && $last_name != "" } {
	incr exception_count
	append exception_text "<li>You can only specify either email or last name, not both.\n"
    }

    if { ![info exists target] || $target == "" } {
	incr exception_count
	append exception_text "<li>Target was not specified. This shouldn't have happened,
please contact the <a href=\"mailto:[ad_host_administrator]\">administrator</a>
and let them know what happened.\n"
    }
}

if { $exception_count != 00 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if { [info exists keyword] } {
    set search_clause "lower(email) like '%[string tolower $QQkeyword]%' or lower(first_names || ' ' || last_name) like '%[string tolower $QQkeyword]%'"
    set search_text "name or email matching \"$keyword\""
} elseif { [info exists email] && $email != "" } {
    set search_text "email \"$email\""
    set search_clause "lower(email) like '%[string tolower $QQemail]%'"
} else {
    set search_text "last name \"$last_name\""
    set search_clause "lower(last_name) like '%[string tolower $QQlast_name]%'"
}

if { ![info exists passthrough] } {
    set passthrough_parameters ""
} else {
    set passthrough_parameters "&[export_entire_form_as_url_vars $passthrough]"
}


if { [exists_and_not_null limit_to_users_in_group_id] } {
set query "select distinct u.user_id as user_id_from_search, 
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

# We are limiting the search to one group - display that group's name
if { [exists_and_not_null limit_to_users_in_group_id] && ![regexp {[^0-9]} $limit_to_users_in_group_id] } {
    set group_text " in [database_to_tcl_string $db "select group_name from user_groups where group_id=$limit_to_users_in_group_id"]"
} else {
    set group_text ""
}

set selection [ns_db select $db $query]



append whole_page "[ad_admin_header "User Search$group_text"]
<h2>User Search$group_text</h2>
for $search_text
<hr>
<ul>
"

set i 0

set user_items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append user_items "<li><a href=\"$target?[export_url_vars user_id_from_search first_names_from_search last_name_from_search email_from_search]$passthrough_parameters\">$first_names_from_search $last_name_from_search ($email_from_search)</a>\n"
    incr i
    if { $user_state != "authorized" } {
	set user_finite_state_links  [ad_registration_finite_state_machine_admin_links $user_state $user_id_from_search]
	append user_items "<font color=red>$user_state</font> [join $user_finite_state_links " | "] \n"
    }
}

if { $i == 0 } {
    append whole_page "<li>No users found.\n"
} else {
    append whole_page $user_items
}

append whole_page "</ul>
[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
