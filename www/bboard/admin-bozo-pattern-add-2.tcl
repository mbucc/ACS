# $Id: admin-bozo-pattern-add-2.tcl,v 3.0.4.1 2000/04/28 15:09:40 carsten Exp $
set_the_usual_form_variables

# topic, topic_id, the_regexp, scope, message_to_user, creation_comment

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



ns_db dml $db "insert into bboard_bozo_patterns
(topic_id, the_regexp, scope, message_to_user, creation_date, creation_user, creation_comment)
values
($topic_id, '$QQthe_regexp', '$QQscope', '$QQmessage_to_user', sysdate, [ad_verify_and_get_user_id], [ns_dbquotevalue $creation_comment text])"


ad_returnredirect "admin-home.tcl?[export_url_vars topic topic_id]"
