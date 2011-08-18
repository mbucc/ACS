# $Id: go.tcl,v 3.0.4.2 2000/04/28 15:11:40 carsten Exp $
# File:        go.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Redirects the user to a view- or edit-presentation screen. Used so we
#              don't have to send long URLs like
#
#                http://lcsweb114.lcs.mit.edu/wimpy/presentation-top.tcl?presentation_id=131
#
#              which are likely to be mangled by mail clients.
# Inputs:      presentation_id as query string (e.g., go.tcl?131)

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

set sample_url [join [lreplace [ns_conn urlv] end end "go.tcl?131"] "/"]

set query [ns_conn query]

# Try to grok the query string. Display a nice error message if it isn't grokable.
if { ![regexp {([0-9]+)} $query all invitation_id req_secret] } {
    ad_return_error "Mangled Link" "We're sorry, but the link you received in your invitation
E-mail must have been mangled by your mail client. It was supposed to end with a number, for example:

<blockquote><pre>[ns_conn location]/$sample_url</pre></blockquote>

<p>Your best bet is probably to try to just try to <a href=\"\">find the presentation yourself</a>.
"
    return
}

set auth [wp_check_authorization $db $query $user_id "read"]
if { $auth == "read" } {
    ad_returnredirect "[wp_presentation_url]/$query/"
} else {
    ad_returnredirect "presentation-top.tcl?presentation_id=$query"
}
