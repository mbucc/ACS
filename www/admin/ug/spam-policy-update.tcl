# $Id: spam-policy-update.tcl,v 3.0.4.1 2000/04/28 15:09:34 carsten Exp $
set_form_variables

# group_id, spam_policy

set db [ns_db gethandle]

ns_db dml $db "
update user_groups 
set spam_policy = '$spam_policy' 
where group_id = $group_id"


ad_returnredirect "group.tcl?[export_url_vars group_id]"