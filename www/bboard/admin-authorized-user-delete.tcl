# $Id: admin-authorized-user-delete.tcl,v 3.0 2000/02/06 03:32:25 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables


# topic, user_id

set db [ns_db gethandle]
 
set user_id_to_delete $user_id


if  {[bboard_get_topic_info] == -1} {
    return}

# cookie checks out; user is authorized


set selection [ns_db 1row $db "select first_names, last_name from
users where user_id=$user_id_to_delete"]
set_variables_after_query


ReturnHeaders

ns_write "[ad_admin_header "Really remove $first_names $last_name"]
<h2>Really remove $first_names $last_name </h2>
from <a href=\"admin-authorized-users.tcl?topic=[ns_urlencode $topic]\">$topic user list?</a>
<hr><p>

<form action=admin-authorized-user-delete-2.tcl method=get>
<input type=hidden name=user_id_to_delete value=\"$user_id_to_delete\">
<input type=hidden name=topic value=\"$topic\">
<input type=submit name=submit value=\"Delete User\">
</form>

<form action=admin-authorized-users.tcl method=get>
<input type=hidden name=user_id_to_delete value=\"$user_id_to_delete\">
<input type=hidden name=topic value=\"$topic\">
<input type=submit name=submit value=\"Cancel\">
</form>

[bboard_footer]"
