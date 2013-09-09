# /groups/admin/group/spam-send.tcl
ad_page_contract {
    @param spam_id the ID of the spam
    @param sento the recipient of the spam
    @param subject the subject line
    @param message the SPAM 

 Purpose:  sends one spam 

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
       @cvs-id spam-send.tcl,v 3.4.2.6 2000/07/24 20:29:59 ryanlee Exp

 } {
    spam_id:notnull,naturalnum
    sendto:notnull
    subject:optional
    from_address:notnull
    message:allhtml,notnull
}


if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

set user_id [ad_verify_and_get_user_id]

if { [lsearch $sendto "all"] != -1 } {
    set role_clause ""
} else {
    foreach recipient_role $sendto {
	append ug_role_clause "ug.role=:recipient_role "
    }
    set role_clause "and ("
    append role_clause [join $ug_role_clause " or "] )
}


set n_receivers_intended [db_string get_n_receivers_intended "
    select count(*)  from ( select distinct email 
    from user_group_map ug, users_spammable u
	where ug.group_id = :group_id
	$role_clause
	and ug.user_id = u.user_id
	and not exists ( select 1 
	                 from group_member_email_preferences
                         where group_id = :group_id
	                 and user_id =  u.user_id 
                         and dont_spam_me_p = 't')
        and not exists ( select 1 
	                 from user_user_bozo_filter
                         where origin_user_id = u.user_id 
	                 and target_user_id =  :user_id))"]


if [catch { db_dml group_spam_insert "insert into group_spam_history
            ( spam_id, group_id, from_address, approved_p, subject, 
              body, send_date,  creation_date, sender_id,
              sender_ip_address, send_to,
              n_receivers_intended, n_receivers_actual)
            values
              (:spam_id, :group_id, :from_address, 't', :subject, 
               empty_clob(), null, sysdate, :user_id, 
               '[ns_conn peeraddr]', :sendto, 
               :n_receivers_intended ,0)
             returning body into :1" -clobs [list $message]  } errmsg] {
    
    # choked; let's see if it is because 
    if { [db_string get_count_from_gsh "select count(*)
    from group_spam_history 
    where spam_id = :spam_id"] > 0 } {
	# double click
	ad_returnredirect spam-index
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

db_release_unused_handles
ad_returnredirect spam-index

ns_conn close

ns_log Notice "/groups/admin/group/spam-send:  sending group spam $spam_id"
send_one_group_spam_message $spam_id
ns_log Notice "/groups/admin/group/spam-send: group spam $spam_id sent"

	  
	
