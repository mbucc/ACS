# $Id: administrator-add.tcl,v 3.0.4.1 2000/04/28 15:08:24 carsten Exp $
set_the_usual_form_variables

# topic, topic_id, user_id_from_search

set db [ns_db gethandle]

ad_administration_group_user_add $db $user_id_from_search "administrator" "bboard" $topic_id

ad_returnredirect "topic-administrators.tcl?[export_url_vars topic topic_id]"
