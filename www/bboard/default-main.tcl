ad_page_contract {
    A generic main page
    
    @param topic_id the ID for this bboard topic

    @cvs-id default-main.tcl,v 3.3.2.5 2000/09/22 01:36:49 kevin Exp
} {
    topic_id:integer,notnull
}
 
# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

append page_content "
[ad_header "Default"]
"

if { $users_can_initiate_threads_p != "f" } {
    append page_content "
\[
<a href=\"post-new?[export_url_vars topic topic_id]\">Post New Message </a> 
\]

<p>"
} 

append page_content "
<h3>$topic</h3>
Click on a subject line above to see the full message that corresponds
to it.
"

if { [bboard_pls_blade_installed_p] } {

	append page_content "<form method=get action=search target=\"_top\">
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
	    set administrator_p [bboard_user_is_admin_for_topic $user_id $topic_id]
	}
    }
}

if { $administrator_p == 0 } {    
    append page_content "This forum is maintained by <a href=\"/shared/community-member?user_id=$primary_maintainer_id\">$maintainer_name</a>. "
} else {
    append page_content "<A href=\"admin-home?[export_url_vars topic]\">Administrator page</a>"
}

append page_content "<p>If you want to follow this discussion by email, 
<a href=\"add-alert?[export_url_vars topic topic_id]\" target=\"_top\">
click here to add an alert</a>.
[bboard_footer]
"

doc_return  200 text/html $page_content














