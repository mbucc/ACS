ad_page_contract {
    @param user_id
    @author ?
    @creation-date ?
    @cvs-id demographic-edit.tcl,v 3.2.2.3.2.4 2000/09/22 01:36:18 kevin Exp
} {
    user_id:integer,notnull
}


if [info exists user_id_from_search] {
    set user_id $user_id_from_search
}


db_0or1row user_full_name "select first_names, last_name from users where user_id = :user_id"

if { [empty_string_p $first_names] && [empty_string_p $last_name] } {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was nuke?"
    return
}

append whole_page "[ad_admin_header "Demographic information  for $first_names $last_name"]

<h2>Demographic information for $first_names $last_name</h2>

"

append whole_page "<p>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "one.tcl?[export_url_vars user_id]" "One User"] "Demographic Information"]

<hr>
"


append whole_page "
[ad_admin_footer]
"

doc_return  200 text/html $whole_page





