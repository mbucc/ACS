# $Id: content-section-edit-1.tcl,v 3.0 2000/02/06 03:15:08 ron Exp $
# File:     /admin/content-sections/content-section-edit-1.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  editing a content section
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# section_key

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

if {[catch {set selection [ns_db 1row $db "
    select section_key, section_pretty_name, section_type, section_url_stub, sort_key,
           requires_registration_p, visibility, intro_blurb, help_blurb, module_key
    from content_sections
    where [ad_scope_sql] and section_key='$QQsection_key'"]} errmsg]} {
    ad_scope_return_error "Error in finding the data" "We encountered an error in querying the database for your object.
Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>" $db
    return
} 


set_variables_after_query

# now we have the values from the database.

switch $section_type {
    admin {set type_name Module}
    system {set type_name Module}
    custom {set type_name "Custom Section"}
    static {set type_name "Static Section"}
}

ReturnHeaders

set page_title "Edit $type_name $section_pretty_name"
ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Content Sections"] [list "content-section-edit.tcl?[export_url_scope_vars section_key]" "Property"] "Edit" ]
<hr>
"

append html "
<table>
"

if { ([string compare $section_type admin]==0) || ([string compare $section_type system]==0) } {
    append html "
    <tr><th valign=top align=left>Module
    <td>[database_to_tcl_string $db "select pretty_name from acs_modules where module_key='[DoubleApos $module_key]'"]</td></tr>
    "
}

append html "
<form method=POST action=content-section-edit-2.tcl>
[export_form_scope_vars section_key section_type]

<tr><th valign=top align=left>Section key</th>
<TD><input type=text size=20 MAXLENGTH=30 name=new_section_key [export_form_value section_key]></TD></TR>

<tr><th valign=top align=left>Section pretty name</th>
<td><input type=text size=40 MAXLENGTH=200 name=section_pretty_name [export_form_value section_pretty_name]></td></tr>
"

if { [string compare $section_type static]==0 } {
    append html "
    <tr><th valign=top align=left>Section url stub</th>
    <TD><input type=text size=40 MAXLENGTH=200 name=section_url_stub [export_form_value section_url_stub]></TD></TR>
    "
}

append html "
<tr><th valign=top align=left>Sort key</th>
<TD><input type=text size=10 MAXLENGTH=22 name=sort_key [export_form_value sort_key]></TD></TR>
"

if { [string compare $section_type static]==0 || [string compare $section_type custom]==0 } {
    append html "
    <tr><th valign=top align=left>Requires registration?</th>
    <td>[ns_htmlselect -labels {Yes No} requires_registration_p {t f} $requires_registration_p]</td></tr>
    
    <tr><th valign=top align=left>Visible to everybody?</th>
    <td>[ns_htmlselect -labels {Yes No} visibility {public private} $visibility]</td></tr>
    "
}

append html "
<tr><th valign=top align=left>Introduction blurb</th>
<td><textarea name=intro_blurb cols=40 rows=8 wrap=soft>[ns_quotehtml $intro_blurb]</textarea></td></tr>

<tr><th valign=top align=left>Help blurb</th>
<td><textarea name=help_blurb cols=40 rows=8 wrap=soft>[ns_quotehtml $help_blurb]</textarea></td></tr>

</table>
<p>
<center>
<input type=submit value=\"Update\">
</center>
</form>
<p>
"

ns_write "
$html
[ad_scope_admin_footer]
"






