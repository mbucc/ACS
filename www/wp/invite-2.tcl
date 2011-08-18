# $Id: invite-2.tcl,v 3.0 2000/02/06 03:54:57 ron Exp $
# File:        invite-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Sends an invitation E-mail.
# Inputs:      presentation_id, role, name, email, message

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

set exception_count 0
set exception_text ""

if { ![info exists name] || $name == "" } {
    append exception_text "<li>Please provide the name of the user you're inviting.\n"
    incr exception_count
}
if { [string length $name] > 200 } {
    append exception_text "<li>The name is too long.\n"
}
if { ![info exists email] || $email == "" || ![regexp {^.+@.+$} $email] } {
    append exception_text "<li>Please provide the E-mail address of the user you're inviting.\n"
    incr exception_count
}
if { [string length $email] > 200 } {
    append exception_text "<li>The E-mail address is too long.\n"
}
if { [database_to_tcl_string $db "
    select count(*)
    from wp_user_access_ticket
    where presentation_id = [wp_check_numeric $presentation_id]
    and role = '$QQrole'
    and email = '$QQemail'
"] != 0 } {
    append exception_text "<li>This person has already been invited to [wp_role_predicate $role $title].\n"
    incr exception_count
}

set selection [ns_db 0or1row $db "select first_names, last_name, user_id req_user_id from users where email = '$QQemail'"]
if { $selection != "" } {
    set_variables_after_query
    append exception_text "<li>$first_names $last_name ($email) already has an account on [ad_system_name].
<a href=\"presentation-acl-add-2.tcl?presentation_id=$presentation_id&role=$role&user_id_from_search=[ns_urlencode $user_id]&first_names_from_search=[ns_urlencode $first_names]&last_name_from_search=[ns_urlencode $last_name]\">Follow this link to invite $first_names $last_name</a>.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# Generate a random 8-digit number as the secret code.
set secret [expr 10000000 + [randomRange 90000000]]

ns_db dml $db "begin transaction"

# Make sure the insertion works before sending the E-mail. But do it all
# within a transaction, so if the E-mail fails we cancel the ticket.
set invitation_id [wp_nextval $db "wp_ids"]
ns_db dml $db "
    insert into wp_user_access_ticket(invitation_id, presentation_id, role, name, email, secret, invite_date, invite_user)
    values ($invitation_id, $presentation_id, '$QQrole', '$QQname', '$QQemail', '$secret', sysdate, $user_id)
"

set selection [ns_db 1row $db "select first_names || ' ' || last_name my_name, email my_email from users where user_id = $user_id"]
set_variables_after_query

# Can the user just view the presentation (read), or work on it (write/admin)?
if { $role == "read" } {
    set predicate "view"
} else {
    set predicate "work on"
}

# Use a short URL, so it doesn't get mangled or wrapped.
#
#   http://lcsweb114.lcs.mit.edu/wimpy/join.tcl?131_92775918
#   (56 characters)
#
# instead of
#
#   http://lcsweb114.lcs.mit.edu/wimpy/join.tcl?presentation_id=131&secret=92775918
#   (79 characters)

set url [join [lreplace [ns_conn urlv] end end "join.tcl?${invitation_id}_$secret"] "/"]

set message [wrap_string "Hello! I have invited you to $predicate the WimpyPoint presentation named

  $title

on [ad_system_name]. To do so, you'll need to register for an account on [ad_system_name]. The process is very simple (and doesn't require you to provide any personal information). Just follow this link:

  [ns_conn location]/$url

$message" 75]

ns_sendmail "$name <$email>" "$my_name <$my_email>" "WimpyPoint Invitation: $title" $message "" "$my_name <$my_email>"

ns_db dml $db "end transaction"

ReturnHeaders
ns_write "[wp_header_form "action=invite-2.tcl method=post" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl.tcl?presentation_id=$presentation_id" "Authorization"] \
           [list "invite.tcl?presentation_id=$presentation_id&action=$role" "Invite User"] "E-Mail Sent"]

$name ($email) has been invited to $predicate the presentation $title. The following E-mail was sent:

<blockquote><pre>From: [ns_quotehtml "$my_name <$my_email>"]
To: [ns_quotehtml "$name <$email>"]

$message</pre></blockquote>

<p><a href=\"presentation-acl.tcl?presentation_id=$presentation_id\">Return to $title</a>

</p>
[wp_footer]
"

