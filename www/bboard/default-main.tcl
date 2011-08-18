# $Id: default-main.tcl,v 3.1 2000/02/23 01:49:39 bdolicki Exp $
set_the_usual_form_variables

# topic

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return
}

# we found the data we needed
set_variables_after_query

ReturnHeaders

ns_write "<html>
<head>
<title>Default</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

"

if { $users_can_initiate_threads_p != "f" } {
    ns_write "
\[
<a href=\"post-new.tcl?[export_url_vars topic topic_id]\">Post New Message </a> 
\]

<p>"
} 

ns_write "

<h3>$topic</h3>

Click on a subject line above to see the full message that corresponds
to it.

"

if { [bboard_pls_blade_installed_p] } {

	ns_write "<form method=get action=search.tcl target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40>
</form>"
}


set user_id [ad_verify_and_get_user_id]

switch $user_id {
    0  { set administrator_p 0 }
    default {
	if { $user_id == $primary_maintainer_id } { 
	    set administrator_p 1 
	} else {
	    set administrator_p [bboard_user_is_admin_for_topic $db $user_id $topic_id]
	}
    }
}

if { $administrator_p == 0 } {    
    ns_write "This forum is maintained by <a href=\"/shared/community-member.tcl?user_id=$primary_maintainer_id\">$maintainer_name</a>. "
} else {
    ns_write "<A href=\"admin-home.tcl?[export_url_vars topic]\">Administrator page</a>"
}

ns_write "<p>If you want to follow this discussion by email, 
<a href=\"add-alert.tcl?[export_url_vars topic topic_id]\" target=\"_top\">
click here to add an alert</a>.


[bboard_footer]
"
