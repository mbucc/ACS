# $Id: presentation-acl-add-3.tcl,v 3.0 2000/02/06 03:55:08 ron Exp $
# File:        presentation-acl-add-3.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Adds a user to an ACL.
# Inputs:      presentation_id, role, user_id_from_search, first_names_from_search, last_name_from_search
#              email (maybe), message

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

set my_email [database_to_tcl_string $db "select email from users where user_id = $user_id"]
set dest_email [database_to_tcl_string $db "select email from users where user_id = $user_id_from_search"]

ns_db dml $db "begin transaction"

# Delete and insert, rather than updating, since we don't know if there's already a row in the table.
ns_db dml $db "delete from user_group_map where group_id = $group_id and user_id = [wp_check_numeric $user_id_from_search]"
ns_db dml $db "
    insert into user_group_map(group_id, user_id, role, mapping_user, mapping_ip_address)
    values($group_id, $user_id_from_search, '$QQrole', $user_id, '[ns_conn peeraddr]')
"

if { $role == "read" } {
    set predicate "view"
} else {
    set predicate "work on"
}

# Send an E-mail message notifying the user.
if { [info exists email] && $email != "" } {
    set url [join [lreplace [ns_conn urlv] end end "go.tcl?$presentation_id"] "/"]

    set message [wrap_string "Hello! I have invited you to $predicate the WimpyPoint presentation named

  $title

on [ad_system_name]. To do so, just follow this link:

  [ns_conn location]/$url

$message" 75]

    ns_sendmail "$dest_email" "$my_email" "WimpyPoint Invitation: $title" $message "" "$my_email"
}

ns_db dml $db "end transaction"

ReturnHeaders
ns_write "[wp_header_form "action=presentation-acl-add-3.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl.tcl?presentation_id=$presentation_id" "Authorization"] "User Added"]

$first_names_from_search $last_name_from_search ($dest_email) has been given permission to
[wp_role_predicate $role $title].

"

if { [info exists email] && $email != "" } {
    ns_write "The following E-mail was sent: 

<blockquote><pre>From: [ns_quotehtml "$my_email"]
To: [ns_quotehtml "$dest_email"]

$message</pre></blockquote>
"
}

ns_write "
<p><a href=\"presentation-acl.tcl?presentation_id=$presentation_id\">Return to $title</a>

</p>
[wp_footer]
"
