# $Id: aim-tik-by-office.tcl,v 1.1.2.1 2000/03/17 07:25:49 mbryzek Exp $
#
# File: /www/intranet/employees/aim-tik-by-office.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Generates an AIM Tik file of all the employees subdivided by office
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set html "m 1\n"

set selection [ns_db select $db \
	"select distinct ug.group_name, uc.aim_screen_name
           from user_groups ug, user_group_map ugm, users_active users, users_contact uc
          where ug.parent_group_id=[im_office_group_id]
            and ug.group_id=ugm.group_id
            and ugm.user_id=users.user_id
            and users.user_id=uc.user_id
            and users.user_id<>$user_id
            and aim_screen_name is not null
       order by upper(ug.group_name), upper(aim_screen_name)"]



set last_off_name ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_off_name != $group_name } {
	append html "\ng $group_name\n"
	set last_off_name $group_name
    }
    append html "b $aim_screen_name\n"
}

ns_return 200 text/plain $html
