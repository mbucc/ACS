# $Id: edit-index-page.tcl,v 3.0 2000/02/06 03:16:10 ron Exp $
# File:     admin/custom-sections/edit-index-file.tcl
# Date:     12/30/99
# Contact:  ahmeds@mit.edu
# Purpose:  shows custom section index page
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

set exception_count 0
set exception_text ""

set selection [ns_db 0or1row $db "
select body, html_p
from content_sections
where section_id=$section_id
"]

if { [empty_string_p $selection] } {
    set page_exists_p [database_to_tcl_string $db "
    select count(*) 
    from content_sections
    where section_id=$section_id
    "]

    if { !$page_exists_p } {
	incr exception_count
	append exception_text "
	<li>Page does not exits. Only existing pages can be showed.
	"
	
	if { $exception_count > 0 } { 
	    ad_scope_return_complaint $exception_count $exception_text $db
	    return
	}
	
    } 

} else {
    # we got 1 row back, now let's get data from it
    set_variables_after_query
}

set page_title "Index Page"

set section_pretty_name [database_to_tcl_string $db "
    select section_pretty_name 
    from content_sections 
    where section_id = $section_id"]

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_vars section_id]" $section_pretty_name] $page_title]

<hr>
<br>

<blockquote>

(<a href=edit-index-page-1.tcl?[export_url_scope_vars section_id]>edit</a>)
<p>

<b>Page Content</b>
<p>
$body
<p>
Text above is [ad_decode $html_p t HTML "Plain Text"]
<p>

</blockquote>

[ad_scope_admin_footer]
"







