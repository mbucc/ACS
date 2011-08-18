# $Id: admin-update-uploads-anticipated.tcl,v 3.0.4.1 2000/04/28 15:09:41 carsten Exp $
set_the_usual_form_variables

# topic, uploads_anticipated

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
set primary_maintainer_id [database_to_tcl_string $db "select primary_maintainer_id from bboard_topics where topic_id = $topic_id"]

if {[bboard_admin_authorization] == -1} {
	return}

ns_db dml $db "update bboard_topics 
set uploads_anticipated = [ns_dbquotevalue $uploads_anticipated]
where topic_id = $topic_id"

ad_returnredirect "admin-home.tcl?[export_url_vars topic topic_id]"
