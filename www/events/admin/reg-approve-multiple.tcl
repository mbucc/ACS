ad_page_contract {
    Prompts user if he wants to approve multiple registrations.

    @param event_id the event whose multiple registrations we're approving
    @param state the state in which the multiple registrations are in

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-approve-multiple.tcl,v 3.3.6.4 2000/09/22 01:37:39 kevin Exp
} {
    {event_id:integer,notnull}
    {state:notnull}
}


page_validation {
    set err_msg ""
   
    if {$state != "waiting" && $state != "pending" && $state != "shipped"} {
	append err_msg "This page came in with an invalid state"
    }

    if {![empty_string_p $err_msg]} {
	error $err_msg
    }
}

set pretty_event [events_pretty_event $event_id]

set pretty_state [ad_decode $state "shipped" "Confirmed" "pending" "Pending" "waiting" "Wait-listed" $state]

append whole_page "[ad_header "Approve $pretty_state Registrations"]
<h2>Approve $pretty_state Registrations for $pretty_event</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Approve $pretty_state Registrations"]
"

append whole_page "
<hr>
Are you sure you want to approve all [string tolower $pretty_state]
registrants for $pretty_event?  These registrants will be notified
by e-mail.
<form method=post action=\"reg-approve-multiple-2\">
[philg_hidden_input event_id $event_id]
[philg_hidden_input state $state]
<p>
<center>
<input type=submit value=\"Yes, approve these registrants\">
</center>
</form>
[ad_footer]
"


doc_return  200 text/html $whole_page