# $Id: state-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:31 carsten Exp $
set_the_usual_form_variables
# state_name, description

set db [ns_db gethandle]

with_catch errmsg {
    ns_db dml $db "insert into crm_states (state_name, description) values ('$QQstate_name', '$QQdescription')"
} {
    ad_return_warning "Error Creating CRM State" "There was a database error encountered while creating your new customer state. Most likely, there already exists a state of the same name. The Oracle error message was:
<pre>
$errmsg
</pre>
[ad_admin_footer]"
    return
}


ad_returnredirect "index.tcl"