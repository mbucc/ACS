# $Id: index.tcl,v 3.0 2000/02/06 03:16:40 ron Exp $
# File:     /admin/download/index.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  download site wide admin index page
#           presents a list of all the downloadables 
#           and gives option to add new downloadable file

ReturnHeaders

ns_write "
[ad_admin_header "Download Admin Page"]
<h2>Download Admin Page</h2>
[ad_admin_context_bar  "DownLoad"]

<hr>
[help_upper_right_menu]
"

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db2 [lindex $db_pools 1]

set sql_query  "select download_name, download_id, scope, group_id from downloads"
set selection [ns_db select $db $sql_query] 

set html "
Documentation: <a href=/doc/download.html>/doc/download.html</a></br>
User pages: <a href=/download/ >/download</a>
"

append html "
<h4>Downloadable Files</h4>
<ul>
"

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
  
    if { $scope=="group" } {
	set short_name [database_to_tcl_string $db2 "select short_name
	from user_groups
	where group_id = $group_id"]    
    }
    
    if { $scope == "public" } {
	set maintain_link "/download/admin/download-view.tcl?[export_url_vars download_id scope]"
    } else {
	set maintain_link "/groups/admin/$short_name/download/download-view.tcl?[export_url_vars download_id scope group_id]" 
    }
    
    append html "
    <li><a href=\"download-view.tcl?[export_url_vars download_id]\">$download_name</a> "
}

if { $counter == 0 } {
    set html "There are no downloadable files in the database right now.<p>"
} else {
    append html "
    </ul>
    "
}

ns_write "
<p>
<blockquote>
$html
</blockquote>
<p>
[ad_admin_footer]"
