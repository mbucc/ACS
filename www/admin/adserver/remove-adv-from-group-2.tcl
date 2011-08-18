# $Id: remove-adv-from-group-2.tcl,v 3.0.4.1 2000/04/28 15:08:23 carsten Exp $
set_the_usual_form_variables
# group_key, adv_key

set db [ns_db gethandle]

ns_db dml $db "delete from adv_group_map where group_key = '$QQgroup_key'
and adv_key = '$QQadv_key'"

ad_returnredirect "one-adv-group.tcl?group_key=$group_key"
