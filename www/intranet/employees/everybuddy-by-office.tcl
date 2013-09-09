# /www/intranet/employees/everybuddy-by-office.tcl

ad_page_contract {
    Generates an AIM everybuddy (see everybuddy.com) file 
of all the employees subdivided by office

    @param none

    @author dh@arsdigita.com
    @creation-date June 2000

    @cvs-id everybuddy-by-office.tcl,v 3.1.2.8 2000/09/22 01:38:30 kevin Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]


set aim_display_sql "select distinct ug.group_name, uc.aim_screen_name, users.first_names, users.last_name
           from user_groups ug, user_group_map ugm, users_active users, users_contact uc
          where ug.parent_group_id=[im_office_group_id]
            and ug.group_id=ugm.group_id
            and ugm.user_id=users.user_id
            and users.user_id=uc.user_id
            and users.user_id<>:user_id
            and aim_screen_name is not null
       order by upper(ug.group_name), upper(aim_screen_name)"


set last_off_name ""
set html ""

db_foreach aim_display $aim_display_sql {
    if { [string compare $last_off_name $group_name] != 0 } {
	if {![empty_string_p $last_off_name] } {
	    # we need to close a group tag
	    append html "\n</GROUP>\n"
	}
	append html \
"<GROUP> 
 NAME=\"$group_name\"  "
	set last_off_name $group_name
    }
    append html "
 <CONTACT> 
    NAME=\"$first_names $last_name\" 
    DEFAULT_PROTOCOL=\"AIM\" 
    <ACCOUNT AIM> 
           NAME=\"$aim_screen_name\"
    </ACCOUNT> 
 </CONTACT>"
}

set without_office_sql "
    select uc.aim_screen_name, users.first_names, users.last_name
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
	if {![empty_string_p $last_off_name] } {
	    # we need to close a group tag
	    append html "\n</GROUP>\n"
	}
	set last_off_name "No Office Assigned"
	append html \
"<GROUP> 
 NAME=\"No Office Assigned\"  "
    }

    append html "
 <CONTACT> 
    NAME=\"$first_names $last_name\" 
    DEFAULT_PROTOCOL=\"AIM\" 
    <ACCOUNT AIM> 
           NAME=\"$aim_screen_name\"
    </ACCOUNT> 
 </CONTACT>"
}

if {![empty_string_p $last_off_name]} {
    # we need to close the last group tag
    append html "\n</GROUP>"
}



doc_return  200 text/plain $html




