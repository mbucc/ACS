# (bran Feb 25 2000)
# For each topic there must be an administration group:
# Run this Tcl code if you have some primary_maintainer_id's who
# still don't have an appropriate administration group.

 set dbs [ns_db gethandle main 2]
 set db [lindex $dbs 0]
 set db2 [lindex $dbs 1]
 ns_db dml $db "begin transaction"
 set topic_id_list [database_to_tcl_list $db "select topic_id from bboard_topics where topic_id
 not in (select submodule from administration_info where module='bboard')"]
 foreach topic_id $topic_id_list {
   set selection [ns_db 1row $db2 "select primary_maintainer_id, topic from bboard_topics where topic_id=$topic_id"]
   set_variables_after_query
   ad_administration_group_add $db2 "Administration Group for $topic BBoard" "bboard" $topic_id "/bboard/admin-home.tcl?[export_url_vars topic topic_id]" 
   ad_administration_group_user_add $db2 $primary_maintainer_id "administrator" "bboard" $topic_id
 }
 ns_db dml $db "end transaction"
 ns_return 200 text/html OK
