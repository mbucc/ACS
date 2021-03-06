# /www/intranet/member-add-3.tcl

ad_page_contract {
    less stringent on permissions (i.e. any member of the group specified
    in limit_to_users_in_group_id can add themselves or anyone else)

    @param group_id 
    @param user_id_from_search 
    @param role
    @param existing_role
    @param new_role
    @param return_url 
    @param also_add_to_group_id 
    @param limit_to_users_in_group_id 
    @param start_date

    @author mbryzek@arsdigita.com
    @creation-date 4/4/2000

    @cvs-id member-add-3.tcl,v 3.10.2.7 2000/10/27 00:03:00 tony Exp
} {
    group_id:naturalnum,notnull
    { role "" }
    { existing_role "" }
    { new_role "" }
    { user_id_from_search:naturalnum "" }
    { return_url "" }
    { also_add_to_group_id:naturalnum "" }
    { limit_to_users_in_group_id:naturalnum "" }
    start_date:array,date,optional
} -validate {
    start_date_is_needed {
	if { $group_id == [im_employee_group_id] && ![info exists start_date(date)] } {
	    ad_complain
	} elseif { $group_id == [im_employee_group_id] && [empty_string_p $start_date(date)] } {
	    ad_complain
	}
    }
} -errors {
    start_date_is_needed { You must enter the start date of the employee }
}
    

if { [empty_string_p $user_id_from_search] } {
    set user_id_from_search [ad_get_user_id]
}

if { ![exists_and_not_null role] } {
    if { [exists_and_not_null new_role] } {
	set role $new_role
    } elseif { [exists_and_not_null existing_role] } {
	set role $existing_role
    } else {
	ad_return_error "No role specified" "We couldn't figure out what role this new member is supposed to have; either you didn't choose one or there is a bug in our software."
	return
    }
}


set user_id [ad_verify_and_get_user_id]

if { ![db_0or1row get_group_type_policy \
	"select group_type, new_member_policy from user_groups where group_id = :group_id"] } {
    ad_return_error "Couldn't find group" "We couldn't find the group $group_id. Must be a programming error."
    return
}

if { ![ad_administrator_p $user_id] } {

    # Is the person an authorized intranet user?
    if { ![im_user_is_authorized_p $user_id] } {
	if { ![info exists limit_to_users_in_group_id] || ![im_can_user_administer_group $limit_to_users_in_group_id $user_id] } {
	
	    if { $new_member_policy != "open" } {
		ad_return_complaint 1 "<li>The group you are attempting to add a member to 
		does not have an open new member policy."
		return
	    }
	}
    }
}

set mapping_user [ad_get_user_id]

set mapping_ip_address [ns_conn peeraddr]

if { [info exists start_date(date)] } {
    set the_date $start_date(date)
}

db_transaction {
    db_dml user_group_delete \
	    "delete from user_group_map 
             where group_id = :group_id and user_id = :user_id_from_search"

    db_dml user_group_insert \
	    "insert into user_group_map 
                         (group_id, user_id, role, mapping_user, mapping_ip_address) 
                  select :group_id, :user_id_from_search, :role, 
                         :mapping_user, :mapping_ip_address 
                  from dual 
                  where ad_user_has_role_p (:user_id_from_search, :group_id, :role) <> 't'"
    
    # Extra fields
    db_foreach fields \
	    "select field_name from all_member_fields_for_group where group_id = :group_id" {
	
	if { [exists_and_not_null $field_name] } {
	    set field_value [set $field_name]

	    db_dml extra_field_insert \
		    "insert into user_group_member_field_map
	                    (group_id, user_id, field_name, field_value)
                     values (:group_id, :user_id_from_search, :field_name, :field_value)" 
        }
    }

    if { $group_id == [im_employee_group_id] } {
	db_dml insert_start_date {
	    insert into im_employee_info (user_id, start_date)
	    select :user_id_from_search, :the_date from dual 
	    where not exists (select user_id from im_employee_info
	                      where user_id=:user_id_from_search)
	}
	if {[db_resultrows] == 0} {
	    db_dml update_start_date {
		update im_employee_info
		set start_date=:the_date
		where user_id=:user_id_from_search
	    }
	}
    }

} on_error {
    ad_return_error "Database Error" "Error while trying to insert user into a user group.

Database error message was:	
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>	
	
"
  return
}

db_release_unused_handles

if { [exists_and_not_null also_add_to_group_id] } {
    # Have to add the user to one more group - do it!
    ad_returnredirect "member-add-3.tcl?group_id=$also_add_to_group_id&[export_ns_set_vars url [list group_id also_add_to_group_id user_id_from_search]]"
} elseif { [exists_and_not_null return_url] } {
    if {[string match *\[?\]* $return_url] == 1} {
	if {[string match *[ad_urlencode user_id_from_search]* $return_url] == 1} {
	    ad_returnredirect $return_url
	} else {	
	    ad_returnredirect $return_url&[export_url_vars user_id_from_search]
	}
    } else {
	ad_returnredirect $return_url?[export_url_vars user_id_from_search]
    }
} else {
    ad_returnredirect "index"
}

