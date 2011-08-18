# $Id: link.tcl,v 3.0 2000/02/06 03:15:15 ron Exp $
# File:     /admin/content-sections/id/index.tcl
# Date:     29/12/99
# Contact:  ahmeds@mit.edu
# Purpose:  Content Section link main page 
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ReturnHeaders

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]

ad_scope_authorize $db $scope admin group_admin none

set page_title "Section Navigation"

ns_write "
[ad_scope_admin_header $page_title $db ]
[ad_scope_admin_page_title $page_title $db]
 
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Content Sections"] $page_title]

<hr>
[help_upper_right_menu]
<br>
"

# show all the links in the tree structure
# notice the use of outer join to show content
# sections for which no from_to links were defined

set selection [ns_db select $db "
select cs.section_id as from_section_id, 
       csl.to_section_id as to_section_id,
       content_section_id_to_key(cs.section_id) as from_section_key,
       content_section_id_to_key(to_section_id) as to_section_key
from content_sections cs, content_section_links csl
where [ad_scope_sql cs]
and cs.section_id= csl.from_section_id(+)
and cs.enabled_p='t'
and (((csl.from_section_id is null) and (csl.to_section_id is null)) or
     ((enabled_section_p(csl.from_section_id)='t') and enabled_section_p(csl.to_section_id)='t'))
and ( not ((cs.section_type = 'admin') or (cs.section_type = 'static')) ) 
order by from_section_key, to_section_key
"]



set link_counter 0
set last_from_section_id 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $from_section_id!=$last_from_section_id } {

	if { $link_counter > 0 } {
	    append links "
	    </table>
	    <a href=\"add-link.tcl?[export_url_scope_vars]&from_section_id=$last_from_section_id\">
	    \[add link\]</a>
	    <br><br><br><br>
	    </ul>
	    "
	}

	append links "
	$from_section_key
	<ul>
	<table>
	"

    }

    if { ![empty_string_p $to_section_key] } {
	append links "
	<tr>
	<td>
	$to_section_key
	<td><a href=\"delete-link.tcl?[export_url_scope_vars from_section_id to_section_id]\">
            delete</a>
	</tr>
	"
    }

    incr link_counter
    set last_from_section_id $from_section_id
}

if { $link_counter > 0 } {
    append links "
    </table>
    <a href=\"add-link.tcl?[export_url_scope_vars]&from_section_id=$last_from_section_id\">
    \[add link\]</a>
    <br>
    </ul>
    "

    append html "
    <ul>
    $links
    </ul>
    "
} else {
    append html "
    No content sections defined in the database.
    "
}


ns_db releasehandle $db

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

