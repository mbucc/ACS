# $Id: join.tcl,v 3.0 2000/02/06 03:55:00 ron Exp $
# File:        join.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Redeems a wp_user_access_ticket.
# Inputs:      query string of the form "presentation_id,secret", e.g., 131,92775918

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

set sample_url [join [lreplace [ns_conn urlv] end end "join.tcl?131_92775918"] "/"]

set query [ns_conn query]

# Try to grok the query string. Display a nice error message if it isn't grokable.
if { ![regexp {^([0-9]+)_([0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])$} $query all invitation_id req_secret] } {
    ad_return_error "Mangled Link" "We're sorry, but the link you received in your invitation
E-mail must have been mangled by your mail client. It was supposed to end with two numbers separated by an underscore (_).
The second number should have been eight digits long. For example:

<blockquote><pre>[ns_conn location]/$sample_url</pre></blockquote>

<p>Your best bet is probably to try to piece together the URL by hand, or to go ahead and
<a href=\"/register/\">register as a user</a> and then ask the person who sent you
the E-mail to invite you again."
    return
}

set selection [ns_db 0or1row $db "
    select t.*, p.*
    from wp_user_access_ticket t, wp_presentations p
    where t.invitation_id = $invitation_id
    and p.presentation_id = t.presentation_id
"]

if { $selection == "" } {
    ad_return_error "Invitation Invalid" "This invitation link is invalid. This could be because
your mail client mangled the link, or the invitation
has been revoked.

<p>Your best bet is probably to try to go ahead and
<a href=\"/register/\">register as a user</a> and then ask the person who sent you
the E-mail to invite you again."

    return
}

set_variables_after_query

if { $role != "read" } {
    # The user is being granted write access - teleport them to the authoring screen.
    set dest_link "presentation-top.tcl?presentation_id=$presentation_id"
} else {
    # Read access only - just show the presentation.
    set dest_link "[wp_presentation_url]/$presentation_id/"
}

if { $secret == "" } {
    ad_return_error "Already Redeemed" "This invitation has already been redeemed! You probably
already have access to the presentation.

<p><a href=\"$dest_link\">Go to $title</a>
"
    return
}

if { $secret != $req_secret } {
    ad_return_error "Invitation Invalid" "This invitation link is invalid. This could be because
your mail client mangled the link, or the invitation
has been revoked.

<p>Your best bet is probably to try to go ahead and
<a href=\"/register/\">register as a user</a> and then ask the person who sent you
the E-mail to invite you again."

    return
}

if { $user_id != 0 } {
    # Someone currently logged on to ACS is redeeming a ticket. Could be because
    #
    # (a) The person being invited already had an ACS account but the user who
    #     invited him/her just couldn't find it, or
    # (b) The person being invited has just signed up for an account.

    if { $creation_user == $user_id } {
	ad_return_error "Silly!" "You weren't supposed to click on the link in your invitation E-mail - that was intended for
the person you were inviting!"
        return
    }

    ns_db dml $db "begin transaction"
    if { [wp_access $db $presentation_id $user_id $role] != "" } {
	set message "You are already allowed to [wp_short_role_predicate $role $title]."
    } else {
	ns_db dml $db "
            insert into user_group_map(group_id, user_id, role, mapping_user, mapping_ip_address)
            values($group_id, $user_id, '$role', $user_id, '[ns_conn peeraddr]')
        "
	set message "You are now allowed to [wp_short_role_predicate $role $title]."
    }
    # Set secret to null to remember that the ticket is already redeemed.
    ns_db dml $db "update wp_user_access_ticket set secret = null where invitation_id = $invitation_id"
    ns_db dml $db "end transaction"

    ReturnHeaders
    ns_write "[wp_header [list "" "WimpyPoint"] "Welcome!"]

<p>$message

<p><a href=\"$dest_link\">Go to $title</a>

</p>
[wp_footer]
"
} else {
    # Send the user to register, and have him/her sent back here when done (in which
    # case the top branch of this if statement is taken and the user is granted access.

    ReturnHeaders
    ns_write "[wp_header [list "" "WimpyPoint"] "Welcome!"]

<p>Welcome to WimpyPoint! Please <a href=\"/register/?return_url=[ns_urlencode "[ns_conn url]?[ns_conn query]"]\">follow this link</a>
to register for an account on [ad_system_name] (or log in if you already have an account). As soon as that's done,
you'll be able to [wp_short_role_predicate $role $title].

</p>

[wp_footer]
"
}