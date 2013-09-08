# /www/intranet/employees/aim-tik.tcl

ad_page_contract {
    Generates an AIM Tik file of all the employees

    @param no parameters passed in

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id aim-tik.tcl,v 1.2.8.6 2000/09/22 01:38:30 kevin Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]



set html "
m 1
g Buddy
"

set aim_details_sql "select aim_screen_name
from users_active users, user_group_map ugm, users_contact
where users.user_id = users_contact.user_id
and aim_screen_name is not null
and ugm.group_id=[im_employee_group_id]
and ugm.user_id=users.user_id
and users.user_id <> :user_id
order by upper(aim_screen_name)"

db_foreach aim_details $aim_details_sql {
    append html "b $aim_screen_name\n"
}



doc_return  200 text/plain $html
   
