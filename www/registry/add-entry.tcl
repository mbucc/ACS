# $Id: add-entry.tcl,v 3.0.4.1 2000/04/28 15:11:26 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}

set_the_usual_form_variables

set insert_sql "insert into stolen_registry ( stolen_id, user_id, additional_contact_info, manufacturer, model, serial_number, value, posted, story ) 
values ( stolen_registry_sequence.nextval, $user_id, '$QQadditional_contact_info', '$QQmanufacturer', '$QQmodel', '$QQserial_number', $value, sysdate, '$QQstory'  )"

set db [ns_db gethandle]

if [catch { ns_db dml $db $insert_sql } errmsg] {
    ad_return_error "Ouch!" "Problem inserting your entry. <P> Here's what came back from the database:<p><pre><code>$errmsg</code></pre>

Here are some common reasons:  

<ul>
<li>you didn't enter a value or the value wasn't a number
</ul>

"
} else {
    ns_return 200 text/html "[ad_header "Successful Entry"]

<h2>Entry Successful</h2>

in the <a href=index.tcl>Stolen Equipment Registry</a>

<hr>

Your entry has been recorded.  Thank you.

[ad_footer]
"
}

