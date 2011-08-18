# $Id: index.tcl,v 3.0 2000/02/06 03:16:15 ron Exp $
# File:     admin/custom-sections/index.tcl
# Date:     12/30/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  custom sections index page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ReturnHeaders

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# section_id

ad_scope_error_check

set db [ns_db gethandle]

ad_scope_authorize $db $scope admin group_admin none

if { $scope=="group" } {
    set group_public_url [ns_set get $group_vars_set group_public_url]
}

set section_pretty_name [database_to_tcl_string $db "
    select section_pretty_name 
    from content_sections 
    where section_id = $section_id"]

set section_key [database_to_tcl_string $db "
    select section_key 
    from content_sections 
    where section_id = $section_id"]

set page_title "$section_pretty_name Section"

ns_write "
[ad_scope_admin_header $page_title $db ]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar $page_title]

<hr>

"

append html "
<h3>Edit Index Page</h3>

<blockquote>
<li>index.html
[ad_space 1]
(<a href=\"$group_public_url/[ad_urlencode $section_key]/\">view</a> |
 <a href=\"edit-index-page.tcl?[export_url_scope_vars section_id]\">property</a>)
</blockquote>
<br>
"

set selection [ns_db select $db "
select content_file_id, file_name, file_type
from content_files
where section_id=$section_id
"]

set page_counter 0
set photo_counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $file_type=="text/html" } {
    
	

	append page_html "
	<li>$file_name 
	[ad_space 1]
	(<a href=\"$group_public_url/[ad_urlencode $section_key]/$file_name\">view</a> | 
	 <a href=\"edit-page.tcl?[export_url_scope_vars content_file_id section_id]\">property</a>)
	
	"
	incr page_counter
    } else {
	append photo_html "
	<li>$file_name 
	[ad_space 1]
	(<a href=\"$group_public_url/[ad_urlencode $section_key]/$file_name\">view</a> | 
	 <a href=\"delete-file.tcl?[export_url_scope_vars content_file_id section_id]\">delete</a>)
	"
	incr photo_counter
    }
}

if { $page_counter > 0 } {
    append html "
    <h3>Edit Section Pages</h3>
    <blockquote>
    $page_html
    <p>
    "
} else {
    append html "
    No pages defined for this section.
    <blockquote>
    <p>
    "
}

append html "
<a href=\"add-page.tcl?[export_url_scope_vars section_id]\">
Add new page to the section</a>
</blockquote>
<br>
"

if { $photo_counter > 0 } {
    append html "
    <h3>Section Images</h3>
    <blockquote>
    $photo_html
    <p>
" 
} else {
    append html "
    <blockquote>
    No photos uploaded for this section.
    <p>
    "
}

append html "
<a href=\"upload-image.tcl?[export_url_scope_vars section_id]\">
Upload image for the section</a>
</blockquote>
<br>
"

ns_db releasehandle $db

ns_write "
<blockquote>
$html
</blockquote>
<p>
[ad_scope_admin_footer]
"
