# /www/download/admin/download-remove.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  removes a download
#
# $Id: download-remove.tcl,v 3.0.6.2 2000/05/18 00:05:16 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_id

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none
set user_id [download_admin_authorize $db $download_id]


set sql_query "
select download_name
from   downloads 
where  download_id=$download_id"

if {[catch {set selection [ns_db 1row $db $sql_query]} errmsg]} {
    ad_scope_return_error \
	    "Error in finding the data" \
	    "We encountered the following error in querying the database for your object:
    <blockquote>$errmsg</blockquote>" $db
    return
} 

set_variables_after_query

set counter [database_to_tcl_string $db \
	"select count(*) from download_versions where download_id = $download_id "]

set version_count_html [ad_decode $counter 0 "" "with $counter downloadable version(s)"]

# -----------------------------------------------------------------------------

set page_title "Remove $download_name" 

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"]  \
	"Remove"]

<hr>

<p>Are you sure that you want to <b>permanently remove</b> $download_name $version_count_html? </p> 

<center>
<form method=post action=download-remove-2.tcl>
[export_form_scope_vars download_id]
<input type=submit value=\"Yes, I want to remove it!\">
</form>
</center>

[ad_scope_footer]
"
