# $Id: add-adv-to-group-2.tcl,v 3.0.4.1 2000/04/28 15:08:23 carsten Exp $
set_the_usual_form_variables
# group_key, adv_key

set db [ns_db gethandle]

ns_db dml $db "insert into adv_group_map (group_key, adv_key) VALUES ('$QQgroup_key', '$QQadv_key')"

ad_returnredirect "one-adv-group.tcl?group_key=$group_key"