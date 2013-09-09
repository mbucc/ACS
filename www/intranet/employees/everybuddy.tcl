# /www/intranet/employees/everybuddy.tcl

ad_page_contract {
    Generates an AIM everybuddy file of all the employees

    @param none

    @author dh@arsdigita.com
    @creation-date June 2000

    @cvs-id everybuddy.tcl,v 3.1.2.10 2000/09/22 01:38:30 kevin Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]


set aim_name_display_sql "
select aim_screen_name, first_names, last_name
from users_active users, user_group_map ugm, users_contact
where users.user_id = users_contact.user_id
and aim_screen_name is not null
and ugm.group_id=[im_employee_group_id]
and ugm.user_id=users.user_id
and users.user_id <> :user_id
order by upper(aim_screen_name)"

set html "<GROUP>
 NAME=\"Buddies\" "

db_foreach aim_name_display $aim_name_display_sql {
    append html "
 <CONTACT> 
    NAME=\"$first_names $last_name\" 
    DEFAULT_PROTOCOL=\"AIM\" 
    <ACCOUNT AIM> 
           NAME=\"$aim_screen_name\"
    </ACCOUNT> 
 </CONTACT>"
}

append html "
</GROUP>"



doc_return  200 text/plain $html


