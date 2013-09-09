# /www/intranet/users/add-to-office.tcl

ad_page_contract {
    Shows a list of offices to which to add a specified user

    @param user_id User ID
    @param return_url
    
    @author mbryzek@arsdigita.com, Jan 2000
    @creation-date
    @cvs-id add-to-office.tcl,v 3.8.6.6 2000/09/22 01:38:50 kevin Exp
} {
    { user_id:integer "" }
    { return_url "" }
}

# set db [ns_db gethandle]

ad_maybe_redirect_for_registration

set user_name [db_string get_full_name \
	"select first_names || ' ' || last_name from users_active where user_id=:user_id" -default ""]

if { [empty_string_p $user_name] } {
    ad_return_error "User doesn't exists!" "This user does not exist or is inactive"
    return
}

set query "select   g.group_id, g.group_name
           from     user_groups g, im_offices o
           where    o.group_id=g.group_id
           order by lower(g.group_name)"

set results ""

db_foreach group_id_and_name_select $query {
    append results "  <li> <a href=[im_url_stub]/member-add-3?user_id_from_search=$user_id&role=member&[export_url_vars group_id return_url]>$group_name</a>\n"
}

if { [empty_string_p $results] } {
    set page_body "<ul>  <li><b> There are no offices </b></ul>\n" 
} else {
    set page_body "
<b>Choose office for this user:</b>
<ul>$results</ul>
"
}

db_release_unused_handles

set page_title "Add user to office"
set context_bar [ad_context_bar_ws [list "./" "Users"] [list view?[export_url_vars user_id] "One user"] $page_title]

doc_return  200 text/html [im_return_template]
