# /www/admin/search.tcl

ad_page_contract {

    Reusable page for searching for a user by email or last_name.
    Returns to "target" with user_id_from_search, first_names_from_search,
    ast_name_from_search, and email_from_search, and passing along all
    form variables listed in "passthrough".
    
    @cvs-id search.tcl,v 3.7.2.3 2000/09/22 01:36:21 kevin Exp

    @param email search string
    @param last_name search string
    @param keyword For looking through both email and last_name (optional)
    @param target URL to return to
    @param passthrough Form variables to pass along from caller
    @param limit_to_users_in_group_id Limits search to users in the specified group id.  This can be a comma separated list to allow searches within multiple groups. (optional)

    @author Jin Choi (jsc@arsdigita.com)
} {
    {email ""}
    {last_name ""}
    keyword:optional
    target
    {passthrough ""}
    {limit_users_in_group_id ""}
    {only_authorized_p:integer 1}
}



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
    if { (![info exists email] || [empty_string_p $email]) && \
	    (![info exists last_name] || [empty_string_p $last_name]) } {
	incr exception_count
	append exception_text "<li>You must specify either an email address or last name to search for.\n"
    }

    if { [info exists email] && [info exists last_name] && \
	    ![empty_string_p $email] && ![empty_string_p $last_name] } {
	incr exception_count
	append exception_text "<li>You can only specify either email or last name, not both.\n"
    }

    if { ![info exists target] || [empty_string_p $target] } {
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

set where_clause [list]
if { [info exists keyword] } {

    set search_text "name or email matching \"$keyword\""
    set sql_keyword "%[string tolower $keyword]%"
    lappend where_clause "(lower(email) like :sql_keyword or lower(first_names || ' ' || last_name) like :sql_keyword)"
} elseif { [info exists email] && ![empty_string_p $email] } {
    set search_text "email \"$email\""
    set sql_email "%[string tolower $email]%"
    lappend where_clause "lower(email) like :sql_email"
} else {
    set search_text "last name \"$last_name\""
    set sql_last_name "%[string tolower $last_name]%"
    lappend where_clause "lower(last_name) like :sql_last_name"
}


if { $only_authorized_p } {
    lappend where_clause {user_state = 'authorized'}
    set authorized_text "We're only showing authorized users (<a href=\"search?[export_ns_set_vars {url} {only_authorized_p}]&only_authorized_p=0\">show all</a>).<p>"
} else {
    set authorized_text "We're showing all users, authorized or not (<a href=\"search?[export_ns_set_vars {url} {only_authorized_p}]&only_authorized_p=1\">show only authorized</a>).<p>"
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
and ugm.group_id in (:limit_to_users_in_group_id) 
and [join $where_clause "\nand "]"

} else {
set query "select user_id as user_id_from_search, 
  first_names as first_names_from_search, last_name as last_name_from_search,
  email as email_from_search, user_state
from users
where [join $where_clause "\nand "]"
}



# We are limiting the search to one group - display that group's name
if { [exists_and_not_null limit_to_users_in_group_id] && ![regexp {[^0-9]} $limit_to_users_in_group_id] } {
    set group_text " in [db_string user_group_name_from_id "select group_name from user_groups where group_id = :limit_to_users_in_group_id"]"
} else {
    set group_text ""
}



append whole_page "[ad_admin_header "User Search$group_text"]
<h2>User Search$group_text</h2>
for $search_text
<hr>
$authorized_text
<ul>
"

set i 0

set user_items ""

db_foreach user_search_admin $query {
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

append whole_page "</ul>"

if { $i > 30 } {
    append whole_page $authorized_text
}

append whole_page "
[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $whole_page
