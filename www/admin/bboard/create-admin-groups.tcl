# /www/admin/bboard/create-admin-groups.tcl
ad_page_contract {
    For each topic there must be an administration group:
    Run this Tcl code if you have some primary_maintainer_id's who
    still don't have an appropriate administration group.
    
    @author Branimir
    @creation-date 25 Feb 2000
    @cvs-id create-admin-groups.tcl,v 3.1.10.4 2000/09/22 01:34:21 kevin Exp
} {}

# -----------------------------------------------------------------------------

db_transaction {
    set topic_id_list [db_list topics "
    select topic_id from bboard_topics where topic_id
    not in (select submodule from administration_info where module='bboard')"]

    foreach topic_id $topic_id_list {
	db_1row topic_info "
	select primary_maintainer_id, topic 
	from bboard_topics where topic_id=:topic_id"

	ad_administration_group_add "Administration Group for $topic BBoard" "bboard" $topic_id "/bboard/admin-home.tcl?[export_url_vars topic topic_id]" 
	ad_administration_group_user_add $primary_maintainer_id "administrator" "bboard" $topic_id
    }
}


doc_return  200 text/html OK
