# File: /groups/group/spam-send.tcl
# Date: Fri Jan 14 19:27:42 EST 2000
# Contact: ahmeds@mit.edu
# Purpose: sends the spam
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)
#
# $Id: spam-send.tcl,v 3.2.4.1 2000/04/28 15:11:00 carsten Exp $

set_the_usual_form_variables 0
# spam_id sendto subject message 

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member none

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

set spam_policy [database_to_tcl_string $db "select spam_policy
                                            from user_groups
                                            where group_id = $group_id"]
  
set approved_p [ad_decode $spam_policy "open" "'t'" "closed" "'f'" null]
set approved_p [ad_decode $role_clause "and ug.role='administrator'" "'t'" $approved_p]

if [catch { ns_ora clob_dml $db "insert into group_spam_history
            ( spam_id, group_id, from_address, approved_p, subject, 
              body, send_date,  creation_date, sender_id,
              sender_ip_address, send_to,
              n_receivers_intended, n_receivers_actual)
            values
              ($spam_id, $group_id, '$QQfrom_address', $approved_p, '$QQsubject', 
               empty_clob(), null, sysdate, $user_id, 
               '[DoubleApos [ns_conn peeraddr]]', '$QQsendto', 
               $n_receivers_intended ,0)
             returning body into :1" $message  } errmsg] {
    
    # choked; let's see if it is because 
    if { [database_to_tcl_string $db "select count(*)
    from group_spam_history 
    where spam_id = $spam_id"] > 0 } {
	ns_return 200 text/html "
	[ad_scope_header "Double Click?" $db]
	[ad_scope_page_title "Double Click?" $db]
	<hr>
	
	This spam has already been sent.  
	Perhaps you double clicked?  
	In any case, you can check the progress of this spam on
	<a href=\"spam-item.tcl?[export_url_vars spam_id]\">the history page</a>.
	
	[ad_scope_footer]"
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

ns_log Notice "/groups/group/spam-send.tcl:  sending group spam $spam_id"
send_one_group_spam_message $spam_id
ns_log Notice "/groups/group/spam-send.tcl: group spam $spam_id sent"

	  
	  



