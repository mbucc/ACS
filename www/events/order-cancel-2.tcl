set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_the_usual_form_variables
#reg_id

set db [ns_db gethandle]



set selection [ns_db 0or1row $db "select 1 from
events_registrations
where reg_id = $reg_id
and user_id = $user_id
"]

if {[empty_string_p $selection]} {
    ns_db releasehandle $db
    ReturnHeaders
    ns_write "
    [ad_header "Could not find registration"]
    <h2>Could not find Registration</h2>
    [ad_context_bar_ws [list "index.tcl" "Events"] Register]
    <hr>
    Registration $reg_id was not found in the database or does not belong
    to you.

    [ad_footer]"

    return
}

ns_db dml $db "update events_registrations
set reg_state = 'canceled'
where reg_id = $reg_id"

#collect the page for output
set whole_page "[ad_header "Registration Canceled"]
<h2>Registration Canceled</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] Register]
<hr>
Your registration has been canceled.
<p>
<a href=\"index.tcl\">Return to events</a>
[ad_footer]
"

ns_db releasehandle $db
ReturnHeaders
ns_write $whole_page