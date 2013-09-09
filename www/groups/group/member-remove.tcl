#/groups/group/member-remove.tcl
ad_page_contract {
    @cvs-id member-remove.tcl,v 3.1.6.5 2000/09/22 01:38:14 kevin Exp
} {
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set group_name [ns_set get $group_vars_set group_name]
set group_public_url [ns_set get $group_vars_set group_public_url]

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect "/register?return_url=[ad_urlencode $group_public_url/member-remove]"
    return
}



db_dml delete_user_from_ugm "
delete from user_group_map where group_id = :group_id and user_id = :user_id
"


doc_return  200 text/html "
[ad_scope_header "Success"]

<h2>Success</h2>

removing you from <a href=\"$group_public_url/\">$group_name</a>

<hr>

There isn't much more to say.  You can return now 
to [ad_pvt_home_link]

[ad_scope_footer]
"

