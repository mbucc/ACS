ad_page_contract {

    Since we are just directly inserting values into the database,
this page should be doing some additional error checking.  E.g., value
must be a floating point number.

    We also aren't doing any double-click checking.

    @cvs-id add-entry.tcl,v 3.3.2.6 2000/09/22 01:39:16 kevin Exp
} {
    additional_contact_info
    manufacturer:notnull
    model:notnull
    serial_number:notnull
    value:notnull
    story:html,notnull
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}

set insert_sql "insert into stolen_registry (
    stolen_id, user_id, additional_contact_info, manufacturer, model, serial_number, value, posted, story )
values (
    stolen_registry_sequence.nextval, :user_id, :additional_contact_info, :manufacturer, :model, :serial_number, :value, sysdate, :story )"

set bind_vars [ad_tcl_vars_to_ns_set user_id additional_contact_info manufacturer model serial_number value story]

if [catch { db_dml registry_insert $insert_sql -bind $bind_vars } errmsg] {
    ad_return_error "Ouch!" "Problem inserting your entry. <P> Here's what came back from the database:<p><pre><code>$errmsg</code></pre>

Here are some common reasons:  

<ul>
<li>you didn't enter a value or the value wasn't a number
</ul>

"
} else {

    
 
    doc_return  200 text/html "[ad_header "Successful Entry"]

    <h2>Entry Successful</h2>

    in the <a href=index>Stolen Equipment Registry</a>
    <hr>
    Your entry has been recorded.  Thank you.
    [ad_footer]
    "
}
