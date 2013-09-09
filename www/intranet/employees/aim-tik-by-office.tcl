# /www/intranet/employees/aim-tik-by-office.tcl

ad_page_contract {
    Generates an AIM Tik file of all the employees subdivided by office

    @param no parameters passed in

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id aim-tik-by-office.tcl,v 1.3.2.7 2000/09/22 01:38:29 kevin Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]



set html "m 1\n"


set aim_group_details_sql "
select distinct ug.group_name, uc.aim_screen_name
           from user_groups ug, user_group_map ugm, users_active users, users_contact uc
          where ug.parent_group_id=[im_office_group_id]
            and ug.group_id=ugm.group_id
            and ugm.user_id=users.user_id
            and users.user_id=uc.user_id
            and users.user_id<>:user_id
            and aim_screen_name is not null
       order by upper(ug.group_name), upper(aim_screen_name)"

set last_off_name ""

db_foreach aim_group_details $aim_group_details_sql {
    if { $last_off_name != $group_name } {
	append html "\ng $group_name\n"
	set last_off_name $group_name
    }
    append html "b $aim_screen_name\n"
}

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
	append html "\ng No Office Assigned\n"
	set last_off_name "No Office Assigned"
    }
  append html "b $aim_screen_name\n"
}


doc_return  200 text/plain $html
