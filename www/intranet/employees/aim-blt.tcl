# /www/intranet/employees/aim-blt.tcl

ad_page_contract {
    Generates an AIM Blt file of all the employees

    @param no parameters passed in

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id aim-blt.tcl,v 3.2.8.6 2000/09/22 01:38:29 kevin Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]



set html "
Config {
 version 1 
}
Buddy {
 list {
   [ad_parameter SystemName] {
"


set aim_details_sql "
select aim_screen_name
from users_active users, users_contact
where users.user_id = users_contact.user_id
and aim_screen_name is not null
and ad_group_member_p ( users.user_id, [im_employee_group_id] ) = 't'
and users.user_id <> :user_id
order by upper(aim_screen_name)"

db_foreach aim_details $aim_details_sql {
    append html "   \"$aim_screen_name\"\n"
}


append html "  }
 }
}
"



doc_return  200 text/plain $html
