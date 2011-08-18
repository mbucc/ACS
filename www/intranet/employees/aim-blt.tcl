# $Id: aim-blt.tcl,v 3.1.2.1 2000/03/17 07:25:48 mbryzek Exp $
#
# File: /www/intranet/employees/aim-blt.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Generates an AIM Blt file of all the employees

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set html "
Config {
 version 1 
}
Buddy {
 list {
   [ad_parameter SystemName] {
"

set selection [ns_db select $db "
select aim_screen_name
from users_active users, users_contact
where users.user_id = users_contact.user_id
and aim_screen_name is not null
and ad_group_member_p ( users.user_id, [im_employee_group_id] ) = 't'
and users.user_id <> $user_id
order by upper(aim_screen_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append html "   \"$aim_screen_name\"\n"
}

append html "  }
 }
}
"

ns_return 200 text/plain $html
