# /wp/invite-2.tcl
ad_page_contract {
    Sends an invitation E-mail.
    @cvs-id invite-2.tcl,v 3.3.2.9 2000/09/22 01:39:30 kevin Exp
    @creation-date 28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id ID of the presentation
    @param role    Invitee's editing role
    @param name    Name of invitee in email
    @param email   Email address to send invitation to
    @param message Message to append to email
} {
    presentation_id:naturalnum,notnull
    role:notnull
    name:optional
    email:optional
    message:optional
}
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]

wp_check_authorization $presentation_id $user_id "admin"

db_1row pres_verify "
select presentation_id, title
from wp_presentations where presentation_id = :presentation_id" 

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

if { [db_string invite_count_select "
    select count(*)
    from wp_user_access_ticket
    where presentation_id = :presentation_id
    and role = :role
    and email = :email
" ] != 0 } {
    append exception_text "<li>This person has already been invited to [wp_role_predicate $role $title].\n"
    incr exception_count
}

if { [db_0or1row user_info_select "select first_names, last_name, user_id req_user_id from users where email = :email" ] } {
    append exception_text "<li>$first_names $last_name ($email) already has an account on [ad_system_name].
<a href=\"presentation-acl-add-2?presentation_id=$presentation_id&role=$role&user_id_from_search=[ns_urlencode $req_user_id]&first_names_from_search=[ns_urlencode $first_names]&last_name_from_search=[ns_urlencode $last_name]\">Follow this link to invite $first_names $last_name</a>.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# Generate a random 8-digit number as the secret code.
set secret [expr 10000000 + [randomRange 90000000]]

db_transaction {

# Make sure the insertion works before sending the E-mail. But do it all
# within a transaction, so if the E-mail fails we cancel the ticket.

set invitation_id [wp_nextval "wp_ids"]

db_dml invite_insert "
    insert into wp_user_access_ticket(invitation_id, presentation_id, role, name, email, secret, invite_date, invite_user)
    values (:invitation_id, :presentation_id, :role, :name, :email, :secret, sysdate, :user_id)
"

db_1row email_select "select first_names || ' ' || last_name my_name, email my_email from users where user_id = :user_id" 


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

set url [join [lreplace [ns_conn urlv] end end "join?${invitation_id}_$secret"] "/"]

set message [wrap_string "Hello! I have invited you to $predicate the WimpyPoint presentation named

  $title

on [ad_system_name]. To do so, you'll need to register for an account on [ad_system_name]. The process is very simple (and doesn't require you to provide any personal information). Just follow this link:

  [ns_conn location]/$url

$message" 75]

ns_sendmail "$name <$email>" "$my_name <$my_email>" "WimpyPoint Invitation: $title" $message "" "$my_name <$my_email>"

}

db_release_unused_handles

set page_output "[wp_header_form "action=invite-2 method=post" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl?presentation_id=$presentation_id" "Authorization"] \
           [list "invite?presentation_id=$presentation_id&action=$role" "Invite User"] "E-Mail Sent"]

$name ($email) has been invited to $predicate the presentation $title. The following E-mail was sent:

<blockquote><pre>From: [ns_quotehtml "$my_name <$my_email>"]
To: [ns_quotehtml "$name <$email>"]

$message</pre></blockquote>

<p><a href=\"presentation-acl?presentation_id=$presentation_id\">Return to $title</a>

</p>
[wp_footer]
"

doc_return  200 "text/html" $page_output
