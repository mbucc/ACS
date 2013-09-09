# /www/user-search.tcl

ad_page_contract {
    
    Reusable page for searching the users table.
    
    Takes email or last_name as search arguments.  Can be constrained with the argument 
    limit_to_users_in_group_id, which accepts a comma-separated list.

    Generates a list of users who match, and prints the names of the groups searched.

    Each user is a link to $target, with user_id, email, last_name, and first_names passed as URL vars.

    By default these values are passed as user_id_from_search, etc. but the variable names can be set by
    specifying userid_returnas, etc.
    
    @param email     (search string)
    @param last_name (search strings)
    @param target    (URL to return to)
    @param userid_returnas     For returning the user_id into a variable named something other than "user_id_from_search"
    @param firstnames_returnas Likewise 
    @param lastname_returnas
    @param email_returnas
    @param passthrough  (form variables to pass along from caller)
    @param custom_title (if you're doing a passthrough, 
           this title can help inform users for what we searched
    @param limit_to_users_in_group_id (optional, limits our search to
           users in the specified group id. can be a comma separated list.)
    @param subgroups_p t/f - optional. If specified along with
           limit_to_users_in_group_id, searches users who are members of a
           subgroup of the specified group_id
    
    @author philg@mit.edu and authors
    @cvs-id user-search.tcl,v 3.3.2.18 2001/01/11 19:18:14 khy Exp    
} {    
    target
    {userid_returnas "user_id_from_search"}
    {firstnames_returnas "first_names_from_search"}
    {lastname_returnas "last_name_from_search"}
    {email_returnas "email_from_search"}
    { email "" }
    { last_name "" }
    { passthrough {}}
    { display_title "Member Search" }
    { limit_to_users_in_group_id "" }
    { subgroups_p "f" }
}

#### DANGEROUS, BUT CANNOT DO IT WITHOUT CHANING INTERFACE FOR THIS FILE
# set all the variables in passthrough
set form [ns_getform]
#foreach varname $passthrough {
#    set $varname [ns_set get $form $varname]
#}

set passthrough_form_elements ""

foreach varname $passthrough {
    append passthrough_form_elements "$varname=[ns_urlencode [ns_set get $form $varname]]&"
}

##### END DANGEROUS CODE

# Check input.
set errors ""
set exception_count 0

if { $email == "" && $last_name == "" } {
    incr exception_count
    append errors "<li>You must specify either an email address or last name for which to search.\n"
}

if { $email != "" && $last_name != "" } {
    incr exception_count
    append errors "<li>You can only specify either email or last name, not both.\n"
}

if { $target == "" } {
    incr exception_count
    append errors "<li>Target was not specified. This shouldn't have happened,
please contact the <a href=\"mailto:[ad_host_administrator]\">administrator</a>
and let them know what happened.\n"
}


## Verify that limit_to_users_in_group_id is a comma-delineated list. -MJS 7/28

if {![empty_string_p $limit_to_users_in_group_id] } {
     
    regexp {([0-9]+)(,[0-9]+)*} $limit_to_users_in_group_id match first_match last_match
    
    if {[string compare $match $limit_to_users_in_group_id]} {
	
	incr exception_count
	append errors "<LI>List of limiting user-groups was not properly formatted.\n"
	
    } 
}


if { $exception_count} {
    ad_return_complaint $exception_count $errors
    return
}


### Input is reasonably good... set limiting clause for the search
if { $email != "" } {
    set query_string "%[string tolower $email]%"
    set search_html "email \"$email\""
    set search_clause "lower(email) like :query_string"
} else {
    set query_string "%[string tolower $last_name]%"
    set search_html "last name \"$last_name\""
    set search_clause "lower(last_name) like :query_string"
}


### build the search query
if { ![empty_string_p $limit_to_users_in_group_id] } {    


    ## Retrieve the names of specified groups -MJS 7/28
    set group_list [db_list groups "select group_name from user_groups where group_id in ($limit_to_users_in_group_id)"]    
    
    if {[empty_string_p [lindex $group_list 0]]} {
	
	## No group names found - return
	set errors "<LI>None of the specified groups exist.\n"
	ad_return_complaint 1 $errors
	return

    } else {

	## Group name/s found
	
	if {[empty_string_p [lindex $group_list 1]] } {

	    ## Only one group found

	    set group_html "in group [lindex $group_list 0]"

	} else {

	    ## Multiple groups found

	    set group_html "in groups [join $group_list ", "]"

	}	

	# Let's build up the groups sql query we need. Only include
	# the user_groups table if we need to include members 
	# of subgroups.
	if { [string compare $subgroups_p "t"] == 0 } {
	    # Include subgroups - set some text to tell the user we are looking in subgroups
	    append group_html " and any of its subgroups"
	    
	    set group_table ", user_groups ug"
	    set group_sql "ug.group_id = ugm.group_id and (ugm.group_id in ($limit_to_users_in_group_id) or ug.parent_group_id in ($limit_to_users_in_group_id))"
	} else {
	    set group_table ""
	    set group_sql "ugm.group_id in ($limit_to_users_in_group_id)"
	}

    }

    
    # Need the distinct for the join with user_group_map
    set query "select distinct u.user_id as $userid_returnas, 
    u.first_names as $firstnames_returnas, u.last_name as $lastname_returnas,
    u.email as $email_returnas, u.user_state
    from users_active u, user_group_map ugm$group_table
    where u.user_id=ugm.user_id
    and $group_sql
    and $search_clause"
     
} else {
    
    ## No groups specified

    set group_html "in all groups"

    set query "select user_id as $userid_returnas, 
    first_names as $firstnames_returnas, last_name as $lastname_returnas,
    email as $email_returnas, user_state
    from users_active
    where $search_clause"
}


set page_contents "
[ad_header $display_title]
<h2>$display_title</h2>
for $search_html $group_html
<hr>
<ul>
"


# Pass along these variables

## This page takes arguments for the names of the variables it will pass back to you.  
## Each defaults to blah_blah_from_search (see page contract) -MJS 7/25

set  export_vars [list $userid_returnas $firstnames_returnas $lastname_returnas $email_returnas]


db_foreach user_search_query $query {
    set exported_variables [list]
    foreach var $export_vars {
	lappend exported_variables [export_url_vars $var]
    }
    append page_contents "<li><a href=\"$target?$passthrough_form_elements[join $exported_variables "&"]\">[util_striphtml "[set $firstnames_returnas] [set $lastname_returnas] ([set $email_returnas])"]</a>\n"
} if_no_rows {
    append page_contents "<li>No members found.\n"
}



doc_return  200 text/html "
$page_contents
</ul>
[ad_footer]
"

## END FILE user-search.tcl


