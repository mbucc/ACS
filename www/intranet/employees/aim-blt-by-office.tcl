# $Id: aim-blt-by-office.tcl,v 3.1.2.1 2000/03/17 07:25:47 mbryzek Exp $
#
# File: /www/intranet/employees/aim-blt-by-office.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Generates an AIM blt file subdivided by office

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set html "
Config {
 version 1 
}
Buddy {
 list {
"

set selection [ns_db select $db \
	"select distinct ug.group_name, uc.aim_screen_name
           from user_groups ug, users_active users, users_contact uc
          where ug.parent_group_id = [im_office_group_id]
            and ad_group_member_p ( users.user_id, ug.group_id ) = 't'
            and users.user_id = uc.user_id
            and users.user_id <> $user_id
            and aim_screen_name is not null
       order by upper(ug.group_name), upper(aim_screen_name)"]

set last_off_name ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_off_name != $group_name } {
	if { ![empty_string_p $last_off_name] } {
	    append html "    \}\n"
	}
	append html "    \"$group_name\" \{\n"
	set last_off_name $group_name
    }
    append html "        \"$aim_screen_name\"\n"
}

append html "    }
 }
}
"

ns_return 200 text/plain $html
