# /www/admin/custom-sections/index.tcl
ad_page_contract {
    Purpose:  custom sections index page (admin)

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author ahmeds@arsdigita.com
    @creation-date  12/30/99

    @param section_id

    @cvs-id index.tcl,v 3.1.6.7 2000/09/22 01:34:40 kevin Exp
} {
    section_id:integer,notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

if { [string compare $scope group] == 0 } {
    set group_public_url [ns_set get $group_vars_set group_public_url]
}

set section_pretty_name [db_string "cs_select_pretty_name" "
    select section_pretty_name 
 from content_sections 
 where section_id = :section_id" ]

set section_key [db_string "cs_select_section_key" "
    select section_key 
 from content_sections 
 where section_id = :section_id" ]

set page_title "$section_pretty_name Section"

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar $page_title]

<hr>

"

append html "
<h3>Edit Index Page</h3>

<blockquote>
<li>index.html
[ad_space 1]
(<a href=\"$group_public_url/[ad_urlencode $section_key]/?[export_url_vars section_id]\">view</a> |
 <a href=\"edit-index-page?[export_url_vars section_id]\">property</a>)
</blockquote>
<br>
"

set query_sql "
select content_file_id, file_name, file_type 
 from content_files 
 where section_id = :section_id 
"

set page_counter 0
set photo_counter 0

db_foreach select_query $query_sql {

    if { $file_type=="text/html" } {
    

	append page_html "
	<li>$file_name 
	[ad_space 1]
	(<a href=\"$group_public_url/[ad_urlencode $section_key]/$file_name?[export_url_vars content_file_id]\">view</a> | 
	 <a href=\"edit-page?[export_url_vars content_file_id section_id]\">property</a>)
	
	"
	incr page_counter
    } else {
	append photo_html "
	<li>$file_name 
	[ad_space 1]
	(<a href=\"$group_public_url/[ad_urlencode $section_key]/$file_name\">view</a> | 
	 <a href=\"delete-file?[export_url_vars content_file_id section_id]\">delete</a>)
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
<a href=\"add-page?[export_url_vars section_id]\">
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
<a href=\"upload-image?[export_url_vars section_id]\">
Upload image for the section</a>
</blockquote>
<br>
"

db_release_unused_handles

append page_body "
<blockquote>
$html
</blockquote>
<p>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_body
