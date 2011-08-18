# /www/download/admin/index.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  download site wide admin index page
#           presents a list of all the downloadables 
#           and gives option to add new downloadable file
#
# $Id: index.tcl,v 3.0.4.2 2000/05/18 00:05:17 ron Exp $
# -----------------------------------------------------------------------------

set_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none


if { $scope == "public" } {
    set user_page_link "/download/index.tcl?[export_url_scope_vars]"
} else {
    set group_public_url [ns_set get $group_vars_set group_public_url]
    set user_page_link "$group_public_url/download/index.tcl?[export_url_scope_vars]" 
}

set helper_args1 "[list "/doc/download.html" "Documentation"]"
set helper_args2 "[list "$user_page_link" "User pages"]" 

set selection [ns_db select $db "
select download_name, 
       download_id 
from   downloads 
where  [ad_scope_sql]"]

append html "
<h4>Downloadable Files</h4>
<ul>
"

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    append html "
    <li><a href=\"download-view.tcl?[export_url_scope_vars download_id]\">$download_name</a> [ad_space 2] "
}

if { $counter == 0 } {
    set html "There are no downloadable files in the database right now.
    <p>
    <li><a href=\"download-add.tcl?[export_url_scope_vars]\">Add New Download</a>
    "
} else {
    append html "
    </ul>
    <li><a href=\"download-add.tcl?[export_url_scope_vars]\">Add New Download</a>
    "
}

# -----------------------------------------------------------------------------

set page_title "Download Admin Page"

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws [list "/download/" "Download"] "Admin"]

<hr>

[help_upper_right_menu_b $helper_args1 $helper_args2]

<p>
<blockquote>
$html
<p>
</blockquote>

[ad_scope_footer]
"





