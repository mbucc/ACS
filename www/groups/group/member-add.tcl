# File: /groups/group/member-add.tcl
ad_page_contract {
    @cvs-id member-add.tcl,v 3.6.2.7 2000/09/22 01:38:14 kevin Exp


 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)

} {
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set group_name [ns_set get $group_vars_set group_name]
set group_public_url [ns_set get $group_vars_set group_public_url]

set local_user_id [ad_get_user_id]
ad_maybe_redirect_for_registration

# send email to all admins of this group
proc notify_group_admins {group_id subject message {from "system@arsdigita.com"}} {

    db_foreach get_email_list "
    SELECT email FROM users WHERE ad_user_has_role_p ( user_id, :group_id, 'administrator' ) = 't'" {
	if [catch { ns_sendmail $email $from $subject $message "" [ad_system_owner] } errmsg] {
	    # failed
	    ns_log Notice "Failed to send group $group_id membership request alert to admin $email:  $errmsg"
	} else {
	    # succeeded
	    ns_log Notice "Send new group $group_id membership request alert to $email."
	}
    }
}



db_1row get_nmp "
select new_member_policy, email_alert_p from user_groups where group_id = :group_id"

db_1row get_user_info "
select email, first_names, last_name from users where user_id = :local_user_id"


if { $new_member_policy == "closed" } {
    ad_return_error "Group Closed" "You can't sign yourself up to this group.  Only [ad_system_owner] can add you."
} elseif { $new_member_policy == "wait" } {
    db_dml insert_into_ugm_queue "
insert into user_group_map_queue (group_id, user_id, ip_address, queue_date)
(select :group_id, :local_user_id, '[ns_conn peeraddr]', sysdate from dual 
where not exists (select user_id from user_group_map_queue where user_id = :local_user_id and group_id = :group_id))"

if {[string match "t" $email_alert_p]} {
    notify_group_admins $group_id "User [ad_get_user_id] has requested membership in group $group_name" "A user has requested membership in group $group_name.

user_id: [ad_get_user_id]
  email: $email
   name: $first_names $last_name" 
}

doc_return  200 text/html "
[ad_scope_header "Queued"]

<h2>Queued</h2>

<hr>

Your request to join 
<a href=\"$group_public_url/\">$group_name</a> has been queued
for approval by the group administrators.
You can return now 
to [ad_pvt_home_link].

[ad_scope_footer]
"

} elseif { $new_member_policy == "open" } {
    db_dml put_user_in_group_map "
insert into user_group_map 
(group_id, user_id, role, mapping_user, mapping_ip_address)

select :group_id, :local_user_id, 'selfenrolled',:local_user_id, '[ns_conn peeraddr]' from dual where ad_user_has_role_p ( :local_user_id, :group_id, 'selfenrolled' ) <> 't'"
db_release_unused_handles

doc_return  200 text/html "
[ad_scope_header "Success"]

<h2>Success</h2>

add you to <a
href=\"$group_public_url/\">$group_name</a>.

<hr>

There isn't much more to say.  You can return now 
to [ad_pvt_home_link].

[ad_footer]
"
} else {
    ad_return_error "Don't understand policy" "We don't understand $group_name's approval policy:  $new_member_policy.  This is presumably a programming bug."
}

