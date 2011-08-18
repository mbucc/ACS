# $Id: admin-update-primary-maintainer-2.tcl,v 3.0 2000/02/06 03:33:16 ron Exp $
set_the_usual_form_variables

# topic_id, user_id_from_search

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}

ns_db dml $db "update bboard_topics set primary_maintainer_id = $user_id_from_search where topic_id = $topic_id"

ReturnHeaders

ns_write "<html>
<head>
<title>Updated primary maintainer for $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Primary maintainer updated</h2>

for \"$topic\"

<hr>

New Maintainer:  [database_to_tcl_string $db "select first_names || ' ' || last_name || ' ' || '(' || email || ')' 
from users 
where user_id = $user_id_from_search"]

[ad_admin_footer]
"

