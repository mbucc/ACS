# $Id: delete-adv-2.tcl,v 3.0 2000/02/06 02:46:09 ron Exp $
set_the_usual_form_variables

# adv_key

set db [ns_db gethandle]

ReturnHeaders 

ns_write "[ad_admin_header "Deleting $adv_key"]

<h2>Deleting $adv_key</h2>

a rarely used part of <a href=\"index.tcl\">AdServer Administration</a>

<hr>

<ul>
"

ns_db dml $db "begin transaction"

ns_db dml $db "delete from adv_log where adv_key = '$QQadv_key'"

ns_write "<li>Deleted [ns_ora resultrows $db] rows from adv_log.\n"

ns_db dml $db "delete from adv_user_map where adv_key = '$QQadv_key'"

ns_write "<li>Deleted [ns_ora resultrows $db] rows from adv_user_map.\n"

ns_db dml $db "delete from adv_categories where adv_key = '$QQadv_key'"

ns_write "<li>Deleted [ns_ora resultrows $db] rows from adv_categories.\n"

ns_db dml $db "delete from adv_group_map where adv_key = '$QQadv_key'"

ns_write "<li>Deleted [ns_ora resultrows $db] rows from adv_group_map.\n"

ns_db dml $db "delete from advs where adv_key = '$QQadv_key'"

ns_write "<li>Deleted the ad itself from advs.\n"

ns_db dml $db "end transaction"

ns_write "</ul>

Transaction complete.

[ad_admin_footer]
"
