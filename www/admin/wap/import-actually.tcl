# /www/admin/wap/import-actually.tcl

ad_page_contract {
    Grab User Agent names from the web and stuff the db!
    
    @param return_url 
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date  Wed May 24 12:08:02 2000
    @cvs-id  import-actually.tcl,v 1.1.6.4 2000/07/27 18:18:45 gjin Exp
} {
    {return_url {/admin/wap/view-list}}
}


ad_maybe_redirect_for_registration

set user_id [ad_verify_and_get_user_id]

set new_agents_list [wap_import_agent_list]

set agent_count 0
foreach agent $new_agents_list {
    db_dml wap_ua_insert_actually "insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_date,creation_user)
select wap_user_agent_id_sequence.nextval,
       :agent,
       'Imported from the Web.',
       sysdate,
       :user_id
from dual
where not exists (
select 1
from wap_user_agents
where name = :agent
and deletion_date is null)"
}

ad_returnredirect $return_url














