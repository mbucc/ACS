# /www/wp/presentation-acl-add-3.tcl

ad_page_contract {
    Adds a user to an ACL.    
    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999

    @param presentation_id the ID of the presentation
    @param role type of permission being granted (read, write, read)
    @param user_id_from_search user id we are searching to add role
    @param first_names_from_search first name of user
    @param last_name_from_search last name of user
    @param message is a personalized message
    @cvs-id presentation-acl-add-3.tcl,v 3.1.6.9 2000/09/22 01:39:31 kevin Exp

} {
    presentation_id:naturalnum,notnull
    role:notnull
    user_id_from_search:naturalnum,notnull
    first_names_from_search:html,notnull
    last_name_from_search:html,notnull
    {message:html,optional ""}
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

#  # Don't let the administrator add an equivalent or lower access level than was previously there.
if { [wp_access $presentation_id $user_id_from_search $role] != "" } {
    db_release_unused_handles
    ad_return_error "User Already Had That Privilege" "
    That user can already [wp_role_predicate $role]. Maybe you want to
    <a href=\"presentation-acl?presentation_id=$presentation_id\">try again</a>.
  "
}

db_1row presentation_select "
select presentation_id, \
	title, \
	group_id \
	from wp_presentations where presentation_id = :presentation_id" 

set my_email [db_string my_email_select "select email from users where user_id = :user_id"] 


set dest_email [db_string dest_email_select "select email from users where user_id = :user_id_from_search"] 

db_transaction {

# Delete and insert, rather than updating, since we don't know if there's already a row in the table.
db_dml from_user_group_map_delete "delete from user_group_map where group_id = :group_id and user_id = :user_id_from_search"
db_dml into_user_group_map_insert "
    insert into user_group_map(group_id, user_id, role, mapping_user, mapping_ip_address)
    values(:group_id, :user_id_from_search, :role, :user_id, '[ns_conn peeraddr]')
"

if { $role == "read" } {
    set predicate "view"
} else {
    set predicate "work on"
}

# Send an E-mail message notifying the user.
if { [exists_and_not_null dest_email] } {
    set url [join [lreplace [ns_conn urlv] end end "go?$presentation_id"] "/"]

    set my_message [wrap_string "Hello! I have invited you to $predicate the WimpyPoint presentation named

  $title

on [ad_system_name]. To do so, just follow this link:

  [ns_conn location]/$url

$message" 75]

    ns_sendmail "$dest_email" "$my_email" "WimpyPoint Invitation: $title" $my_message "" "$my_email"
}

} on_error {
    db_release_unused_handles
    ad_return_error "Error" "Couldn't invite user $first_names_from_search $last_name_from_search."
    return
}

set page_content ""
append page_content "[wp_header_form "action=presentation-acl-add-3" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl?presentation_id=$presentation_id" "Authorization"] "User Added"]

$first_names_from_search $last_name_from_search ($dest_email) has been given permission to
[wp_role_predicate $role $title].

"

if { [info exists email] && $email != "" } {
    append page_content "The following E-mail was sent: 

<blockquote><pre>From: [ns_quotehtml "$my_email"]
To: [ns_quotehtml "$dest_email"]

$message</pre></blockquote>
"
}

append page_content "
<p><a href=\"presentation-acl?presentation_id=$presentation_id\">Return to $title</a>

</p>
[wp_footer]
"


doc_return  200 "text/html" $page_content



