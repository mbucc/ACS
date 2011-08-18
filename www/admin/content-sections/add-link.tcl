# $Id: add-link.tcl,v 3.1 2000/03/11 03:14:05 michael Exp $
# File:     /admin/content-sections/add-link.tcl
# Date:     29/12/99
# Contact:  ahmeds@mit.edu
# Purpose:  Content Section add link page 
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ReturnHeaders

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# from_section_id 

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none


set from_section_key [database_to_tcl_string $db "
    select section_key from content_sections 
    where section_id = $from_section_id"]

set page_title "Add link from $from_section_key"

set html "
[ad_scope_admin_header $page_title $db ]
[ad_scope_admin_page_title $page_title $db]
 
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Content Sections"] [list "link.tcl?[export_url_scope_vars]" "Link Sections"] $page_title]

<hr>

[help_upper_right_menu]

<br>
"



# show existing links 
set selection [ns_db select $db "
select to_section_id , 
       content_section_id_to_key(to_section_id) as to_section_key
from content_section_links
where from_section_id=$from_section_id
and enabled_section_p(from_section_id)='t'
and enabled_section_p(to_section_id)='t'
order by to_section_key
"]


set link_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append old_links "
    <tr>
    <td>$to_section_key
    </tr>
    "

    incr link_counter
}

if { $link_counter > 0 } {
    append html "
    <h3>$from_section_key</h3>
    <h4>Current Links</h4>
    <ul>
    <table>
    $old_links
    </table>
    </ul>
    <br>
    "
} else {
    append html "
    <h3>$from_section_key</h3>
    "
}

set section_link_id [database_to_tcl_string $db "select section_link_id_sequence.nextval from dual"]

# show all linking possibilities (all content sections for
# which links from from_section_key don't already exist)
set selection [ns_db select $db "
select section_id, section_id as to_section_id , section_key as link_section_key
from content_sections
where group_id=$group_id
and section_id not in ( select to_section_id
                        from content_section_links
                        where from_section_id=$from_section_id
                        and enabled_section_p(from_section_id)='t'
                        and enabled_section_p(to_section_id)='t')
and enabled_p='t'
and ( not (section_type = 'admin')) 
and not (section_id = $from_section_id)
order by section_key
"]


set add_link_counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set to_section_key $link_section_key
    append add_links "
    <a href=\"add-link-2.tcl?[export_url_scope_vars from_section_id to_section_id section_link_id]\">
    $link_section_key</a>
    <br>
    "
    incr add_link_counter
}

if { $add_link_counter > 0 } {
    append html "
    <h4>Add Link to</h4>
    <ul>
    $add_links
    </ul>
    "
} else {
    append html "
    <ul>
    No link additions possible
    </ul>
    "

}


ns_db releasehandle $db

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"











