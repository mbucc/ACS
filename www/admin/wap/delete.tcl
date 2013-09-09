# /www/admin/wap/delete.tcl

ad_page_contract {
    Delete one or more WAP user agents.
    @param user_agent_id
    @param return_url
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date  Wed May 24 06:11:20 2000
    @cvs-id  delete.tcl,v 1.1.6.5 2000/07/21 23:11:13 psu Exp
} {
    { user_agent_id:multiple,naturalnum }
    { return_url {view-list} }
}

ad_maybe_redirect_for_registration

set user_id [ad_verify_and_get_user_id]

# we're guaranteeed to get at least one user_agent_id
#set user_agent_id_set ([join $user_agent_id ,])

set bind_var_list {}

for {set i 0} {$i < [llength $user_agent_id]} {incr i} {
    set bind_var_list_$i [lindex $user_agent_id $i]
    lappend bind_var_list ":bind_var_list_$i"
}


db_dml wap_user_agent_delete "update wap_user_agents
set deletion_date = sysdate,
    deletion_user = :user_id
where user_agent_id in ([join $bind_var_list ","])" 

ad_returnredirect $return_url




