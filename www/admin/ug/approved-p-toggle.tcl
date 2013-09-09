ad_page_contract {
  
    @param group_id the id of the group to perform the action on 
  
    @cvs-id approved-p-toggle.tcl,v 3.1.6.2 2000/07/21 20:20:44 ryanlee Exp

} {
    group_id:notnull,naturalnum
}


db_dml update_approved_p "update user_groups set approved_p = logical_negation(approved_p) where group_id = :group_id"

ad_returnredirect "group?group_id=$group_id"

