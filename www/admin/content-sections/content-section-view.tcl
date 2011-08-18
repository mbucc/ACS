# $Id: content-section-view.tcl,v 3.0 2000/02/06 03:15:12 ron Exp $
# File:     /admin/content-sections/content-section-view.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  shows the properties of the content section
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# section_key

if { ![info exist scope] } {
    set scope public
}

set db [ns_db gethandle]
set selection [ns_db 1row $db "
select section_pretty_name, type, section_url_stub, requires_registration_p,
       decode(sort_key, NULL, 'N/A', sort_key) as sort_key, 
       decode(intro_blurb, NULL, 'N/A', intro_blurb) as intro_blurb,
       decode(help_blurb, NULL, 'N/A', help_blurb) as help_blurb
from content_sections_temp
where [ad_scope_sql] and section_key='[DoubleApos $section_key]'"]

set_variables_after_query

ReturnHeaders

ns_write "
[ad_admin_header "View the entry for $section_pretty_name"]

<h2>View the entry for $section_pretty_name</h2>

[ad_admin_context_bar [list "index.tcl" "Content sections"] "View a content section"]

<hr>
"

append html "
<br>
<table>
<tr><th valign=top align=left>Section key</th>
<td>[ad_space 2] $section_key </td></tr>

<tr><th valign=top align=left>Section pretty name</th>
<td>[ad_space 2] $section_pretty_name </td></tr>

<tr><th valign=top align=left>Type</th>
<td>[ad_space 2] $type</td></tr>

<tr><th valign=top align=left>Requires Registration</th>
<td>[ad_space 2] [ad_decode $requires_registration_p 1 Yes No] </td></tr>
"

if { [string compare $type static]==0 } {
    append html "    
    <tr><th valign=top align=left>Section url stub</th>
    <td>[ad_space 2] <a href=$section_url_stub>$section_url_stub</a> </td></tr>
    "
}

append html "
<tr><th valign=top align=left>Sort key</th>
<td>[ad_space 2] $sort_key </td></tr>

<tr><th valign=top align=left>Introduction blurb</th>
<td>[ad_space 2] $intro_blurb </td></tr>

<tr><th valign=top align=left>Help blurb</th>
<td>[ad_space 2] $help_blurb </td></tr>

</table>
<ul>
<li><a href=\"content-section-edit.tcl?[export_url_vars section_key]\">Edit the data for $section_pretty_name</a><br>
</ul>
<p>
"

ns_write "
$html
[ad_admin_footer]
"
