# $Id: admin-bozo-pattern-delete.tcl,v 3.0.4.1 2000/04/28 15:09:40 carsten Exp $
set_the_usual_form_variables

# topic, topic_id the_regexp 

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}


# cookie checks out; user is authorized

ns_db dml $db "delete from bboard_bozo_patterns 
where topic_id = $topic_id
and the_regexp = '$QQthe_regexp'"

ad_returnredirect "admin-home.tcl?[export_url_vars topic topic_id]"


