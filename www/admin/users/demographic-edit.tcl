# $Id: demographic-edit.tcl,v 3.1 2000/03/09 00:01:34 scott Exp $
set_the_usual_form_variables

# user_id

if [info exists user_id_from_search] {
    set user_id $user_id_from_search
}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select first_names, last_name from users where user_id = $user_id"]

if [empty_string_p $selection] {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was nuke?"
    return
}

set_variables_after_query

append whole_page "[ad_admin_header "Demographic information  for $first_names $last_name"]

<h2>Demographic information for $first_names $last_name</h2>

"

append whole_page "<p>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "one.tcl?[export_url_vars user_id]" "One User"] "Demographic Information"]


<hr>

"

set selection [ns_db 0or1row $db "select * from users_contact where user_id = $user_id"]



append whole_page "
[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
