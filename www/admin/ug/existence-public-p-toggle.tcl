ad_page_contract {
 
    @param group_id the id of the group to perform the action on 

    @cvs-id existence-public-p-toggle.tcl,v 3.1.6.3 2000/07/21 03:58:12 ron Exp

} {
    group_id:naturalnum,notnull
}


db_dml update_existence_public "update user_groups set existence_public_p = logical_negation(existence_public_p) where group_id = :group_id"

ad_returnredirect "group?group_id=$group_id"

