# $Id: aim-tik.tcl,v 1.1.2.1 2000/03/17 07:25:49 mbryzek Exp $
#
# File: /www/intranet/employees/aim-tik.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Generates an AIM Tik file of all the employees
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set html "
m 1
g Buddy
"

set selection [ns_db select $db "
select aim_screen_name
from users_active users, user_group_map ugm, users_contact
where users.user_id = users_contact.user_id
and aim_screen_name is not null
and ugm.group_id=[im_employee_group_id]
and ugm.user_id=users.user_id
and users.user_id <> $user_id
order by upper(aim_screen_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append html "b $aim_screen_name\n"
}

ns_return 200 text/plain $html
