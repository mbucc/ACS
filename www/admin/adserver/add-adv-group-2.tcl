# $Id: add-adv-group-2.tcl,v 3.0.4.1 2000/04/28 15:08:23 carsten Exp $
set_the_usual_form_variables
# group_key, pretty_name

set db [ns_db gethandle]

ns_db dml $db "insert into adv_groups (group_key, pretty_name, rotation_method) VALUES ('$QQgroup_key', '$QQpretty_name', '$QQrotation_method')"

ad_returnredirect "one-adv-group.tcl?group_key=$group_key"
