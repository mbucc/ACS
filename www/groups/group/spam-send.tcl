# File: /groups/group/spam-send.tcl

ad_page_contract {
    @param spam_id the ID of the spam
    @param sendto the recipient
    @param subject the subject
    @param message the message itself

    @cvs-id spam-send.tcl,v 3.7.2.14 2000/09/22 01:38:15 kevin Exp
} {
    spam_id:notnull,naturalnum
    from_address:notnull
    sendto:notnull
    subject:optional
    message:optional,html
}


ad_scope_authorize $scope all group_member none

set user_id [ad_verify_and_get_user_id]

if { [lsearch $sendto "all"] != -1 } {
    set role_clause ""
} else {
    set count 0
    foreach recipient_role $sendto {
	set ug_role_$count $recipient_role
	append ug_role_clause "ug.role=:ug_role_$count"
	incr count
    }
    set role_clause "and ("
    append role_clause [join $ug_role_clause " or "] )
}

set n_receivers_intended [db_string get_count_of_email "
    select count(*) from ( select distinct email 
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

  
if { [string compare $sendto "administrator"] == 0 } {
    set approved_p "t"
}  else {
    set spam_policy [db_string get_spam_policy "select spam_policy
                                            from user_groups
                                            where group_id = :group_id"]
  
    set approved_p [ad_decode $spam_policy "open" "t" "closed" "f" [db_null]]
    set approved_p [ad_decode $sendto "administrator" "t" $approved_p]
}

set peeraddr [ns_conn peeraddr]

if [catch { 
    db_dml dump_info_spam_history "
	insert into group_spam_history
	( spam_id, group_id, from_address, approved_p, subject, 
	  body, send_date,  creation_date, sender_id,
	  sender_ip_address, send_to,
	  n_receivers_intended, n_receivers_actual)
	values
	(:spam_id, :group_id, :from_address, :approved_p, :subject, 
	 empty_clob(), NULL, sysdate, :user_id, 
	 :peeraddr, :sendto, 
	 :n_receivers_intended, 0)
	returning body into :1
    " -clobs [list $message] 

} errmsg] {
    
    # choked; let's see if it is because 
    if { [db_string get_is_double_click_cnt "select count(*)
    from group_spam_history 
    where spam_id = :spam_id"] > 0 } {
	doc_return  200 text/html "
	[ad_scope_header "Double Click?"]
	[ad_scope_page_title "Double Click?"]
	<hr>
	
	This spam has already been sent.  
	Perhaps you double clicked?  
	In any case, you can check the progress of this spam on
	<a href=\"spam-item?[export_url_vars spam_id]\">the history page</a>.
	
	[ad_scope_footer]"
    } else {
	ad_return_error "Ouch!"\
		"The database choked on your insert:
	<blockquote>
	$errmsg
	approved_p = $approved_p
	</blockquote>
		      "
    } 
    return
}

db_release_unused_handles
ad_returnredirect spam-index

ns_conn close

ns_log Notice "/groups/group/spam-send.tcl:  sending group spam $spam_id"
send_one_group_spam_message        $spam_id
ns_log Notice "/groups/group/spam-send.tcl: group spam $spam_id sent"
