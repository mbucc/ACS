# $Id: admin-bozo-pattern-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:41 carsten Exp $
set_the_usual_form_variables

# topic, topic_id, the_regexp, the_regexp_old,  scope, message_to_user, creation_comment

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}
 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



ns_db dml $db "update bboard_bozo_patterns set 
the_regexp = '$QQthe_regexp',
scope = '$QQscope',
message_to_user = '$QQmessage_to_user',
creation_comment =  [ns_dbquotevalue $creation_comment text]
where topic_id = $topic_id
and the_regexp = '$QQthe_regexp_old'"

ad_returnredirect admin-bozo-pattern.tcl?[export_url_vars topic topic_id the_regexp]


