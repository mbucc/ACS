# $Id: index.tcl,v 3.0 2000/02/06 03:37:38 ron Exp $
# File:     /custom-sections/index.tcl
# Date:     12/28/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  this serves the custom section index page 
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# section_id 

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all all none

set selection [ns_db 1row $db "
select body, html_p, section_pretty_name
from content_sections
where section_id=$section_id"]

set_variables_after_query

set page_title $section_pretty_name

ReturnHeaders

append html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws "$page_title"]
<hr>
[ad_scope_navbar]
"

set selection [ns_db select $db "
select file_name, page_pretty_name
from content_files
where section_id=$section_id
and file_type='text/html'
order by file_name
"]
    
set page_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append page_links " 
    <li><a href=\"$file_name\">$page_pretty_name</a>
    <br> "
    
    incr page_counter
}

ns_db releasehandle $db    

if { $page_counter==0 } {
    append html "
    <p>
    "     
} else {
    append html "
    <p>
    <ul>
    $page_links
    </ul>
    <p>
	"
}

if { ![empty_string_p $body] } {    
    append html "
    [util_maybe_convert_to_html $body $html_p]	
    "
}

ns_write "
$html
[ad_scope_footer ]
"






