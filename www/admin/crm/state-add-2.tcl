# /www/admin/crm/state-add-2.tcl

ad_page_contract {
    @param state_name
    @param description
    @author Jin Choi(jsc@arsdigita.com)
    @cvs-id state-add-2.tcl,v 3.2.2.10 2000/09/22 01:34:38 kevin Exp
} {
    state_name:notnull,trim
    description:notnull
} 

db_dml crm_state_insert "insert into crm_states (state_name, description) 
  select :state_name, :description from dual
  where not exists (select 1 from crm_states where state_name = :state_name)"

set insert_succ_p [db_string crm_state_insert_check "select count(*) from crm_states where state_name = :state_name and description = :description"]

db_release_unused_handles

if { $insert_succ_p } {
    ad_returnredirect "index"
} else {
    doc_return  200 text/html "[ad_header "State not added"]
  <h2>State not added</h2>
    [ad_admin_context_bar [list "/admin/crm" CRM] "Add a State"]
    <hr>
    <p> We are sorry. The state <i>$state_name</i> could not be added because a state of the same
    name exists already.
    
    [ad_footer]"
}
