# $Id: update-adv-group.tcl,v 3.0.4.1 2000/04/28 15:08:23 carsten Exp $
set_the_usual_form_variables
# pretty_name, group_key

set db [ns_db gethandle]

ns_db dml $db "update adv_groups set pretty_name='$QQpretty_name' where group_key='$QQgroup_key'"

ad_returnredirect "one-adv-group.tcl?group_key=$group_key"


