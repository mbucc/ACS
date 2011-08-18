# $Id: spam-send.tcl,v 3.1.4.1 2000/04/28 15:10:59 carsten Exp $
# File:     /groups/admin/group/spam-send.tcl
# Date:     Mon Jan 17 13:39:51 EST 2000
# Contact:  ahmeds@mit.edu
# Purpose:  sends one spam 
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# spam_id sendto subject message 

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

set user_id [ad_verify_and_get_user_id $db]

set role_clause [ad_decode $sendto "members" "" "and ug.role='administrator'"]

set n_receivers_intended [database_to_tcl_string $db "
    select count(*)
    from user_group_map ug, users_spammable u
	where ug.group_id = $group_id
	$role_clause
	and ug.user_id = u.user_id
	and not exists ( select 1 
	                 from group_member_email_preferences
                         where group_id = $group_id
	                 and user_id =  u.user_id 
                         and dont_spam_me_p = 't')
        and not exists ( select 1 
	                 from user_user_bozo_filter
                         where origin_user_id = u.user_id 
	                 and target_user_id =  $user_id)"]


if [catch { ns_ora clob_dml $db "insert into group_spam_history
            ( spam_id, group_id, from_address, approved_p, subject, 
              body, send_date,  creation_date, sender_id,
              sender_ip_address, send_to,
              n_receivers_intended, n_receivers_actual)
            values
              ($spam_id, $group_id, '$QQfrom_address', 't', '$QQsubject', 
               empty_clob(), null, sysdate, $user_id, 
               '[DoubleApos [ns_conn peeraddr]]', '$QQsendto', 
               $n_receivers_intended ,0)
             returning body into :1" $message  } errmsg] {
    
    # choked; let's see if it is because 
    if { [database_to_tcl_string $db "select count(*)
    from group_spam_history 
    where spam_id = $spam_id"] > 0 } {
	# double click
	ad_returnredirect spam-index.tcl
    } else {
	ad_return_error "Ouch!"\
		"The database choked on your insert:
	<blockquote>
	$errmsg
	</blockquote>
		      "
    } 
    return
}

ns_db releasehandle $db
ad_returnredirect spam-index.tcl

ns_conn close

ns_log Notice "/groups/admin/group/spam-send.tcl:  sending group spam $spam_id"
send_one_group_spam_message $spam_id
ns_log Notice "/groups/admin/group/spam-send.tcl: group spam $spam_id sent"

	  
	
