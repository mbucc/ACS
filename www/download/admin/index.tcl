# /www/download/admin/index.tcl
ad_page_contract {
    download site wide admin index page
    presents a list of all the downloadables 
    and gives option to add new downloadable file

    @param scope the scope (public or group)
    @param group_id the group_id for group scope

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id index.tcl,v 3.11.2.6 2000/09/24 22:37:16 kevin Exp
} {
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check


ad_scope_authorize $scope admin group_admin none

set user_page_link "/download/index?[export_url_scope_vars]"

set helper_args1 "[list "/doc/download.html" "Documentation"]"
set helper_args2 "[list "$user_page_link" "User pages"]" 

append html "
<h4>Downloadable Files</h4>
<ul>
"

db_foreach scope_downloads "
select download_name, 
       download_id 
from   downloads 
where  [ad_scope_sql]" {

    append html "
    <li><a href=\"download-view?[export_url_scope_vars download_id]\">$download_name</a> [ad_space 2] "

} if_no_rows {

    append html "There are no downloadable files in the database right now.
    "
} 

append html "
<p>
<li><a href=\"download-add?[export_url_scope_vars]\">Add New Download</a>
</ul>
"


# -----------------------------------------------------------------------------

set page_title "Download Admin Page"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws [list "/download/index?[export_url_scope_vars]" "Download"] "Admin"]

<hr>

[help_upper_right_menu_b $helper_args1 $helper_args2]

<p>
<blockquote>
$html
<p>
</blockquote>

[ad_scope_footer]
"

