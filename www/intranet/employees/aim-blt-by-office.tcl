# /www/intranet/employees/aim-blt-by-office.tcl

ad_page_contract {
    Generates an AIM blt file subdivided by office


    @param no parameters passed in

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id aim-blt-by-office.tcl,v 3.2.8.7 2000/09/22 01:38:29 kevin Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]


set html "
Config {
 version 1 
}
Buddy {
 list {
"



ns_log notice "*Tony: office group id = [im_office_group_id]"
set aim_office_details_sql "select distinct ug.group_name, uc.aim_screen_name
           from user_groups ug, users_active users, users_contact uc
          where ug.parent_group_id = [im_office_group_id]
            and ad_group_member_p ( users.user_id, ug.group_id ) = 't'
            and users.user_id = uc.user_id
            and users.user_id <> :user_id
            and aim_screen_name is not null
       order by upper(ug.group_name), upper(aim_screen_name)"

set last_off_name ""

db_foreach aim_office_details $aim_office_details_sql {
    if { $last_off_name != $group_name } {
	if { ![empty_string_p $last_off_name] } {
	    append html "    \}\n"
	}
	append html "    \"$group_name\" \{\n"
	set last_off_name $group_name
    }
    append html "        \"$aim_screen_name\"\n"
}
append html "    \}\n"

set without_office_sql "
    select uc.aim_screen_name
    from users_active users, users_contact uc
    where ad_group_member_p ( users.user_id, [im_employee_group_id] ) = 't'
    and users.user_id = uc.user_id
    and users.user_id <> :user_id
    and aim_screen_name is not null
    and not exists (select ug.group_id from user_groups ug 
                    where ug.parent_group_id = [im_office_group_id]
                    and ad_group_member_p ( users.user_id, ug.group_id ) = 't')
    order by upper(aim_screen_name) 
"
 
db_foreach people_without_office $without_office_sql {
    if { [string compare $last_off_name "No Office Assigned"] != 0 } {
	append html "    \"No Office Assigned\" \{\n"
	set last_off_name "No Office Assigned"
    }
  append html "        \"$aim_screen_name\"\n"
}

if { [string compare $last_off_name "No Office Assigned"] == 0 } {
    append html "    \}\n"
}

append html "    
 }
}
"



doc_return  200 text/plain $html
