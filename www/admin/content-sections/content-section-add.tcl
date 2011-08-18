# $Id: content-section-add.tcl,v 3.0 2000/02/06 03:15:07 ron Exp $
# File:     /admin/content-sections/content-section-add.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  adding a content section
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none


if { ![info exists type] } {
    set type section
}

set section_id [database_to_tcl_string $db "select content_section_id_sequence.nextval from dual"]

ReturnHeaders 

switch $type {
    module {
	set page_title "Add Module"
    }
    static {
	set page_title "Add Static Section"
    }
    custom {
	set page_title "Add Custom Section"
    }
}

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Content Sections"] $page_title]
<hr>
"

append html "
<form method=post action=\"content-section-add-2.tcl\"> 
[export_form_scope_vars section_id]

<table>
<tr><th valign=top align=left>Section key</th>
<td><input type=text size=20 name=section_key MAXLENGTH=30></td></tr>

<tr><th valign=top align=left>Section pretty name</th>
<td><input type=text size=40 name=section_pretty_name MAXLENGTH=200></td></tr>
"

if { [string compare $type static]==0 } {
    set section_type static
    append html "
    [export_form_scope_vars section_type ]
    "
}
if { [string compare $type custom]==0 } {
    set section_type custom
    append html "
    [export_form_scope_vars section_type]
    "
}

if { [string compare $type static]==0 } {
    append html "
    <tr><th valign=top align=left>Section url stub</th>
    <td><input type=text size=40 name=section_url_stub MAXLENGTH=200></td></tr>
    "
}



if { $type=="module"} {

    set selection [ns_db select $db "
    select module_key, pretty_name 
    from acs_modules
    where supports_scoping_p='t'
    and module_key not in (select module_key
                           from content_sections
                           where [ad_scope_sql]
                           and (section_type='system' or section_type='admin'))
    "]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	lappend name_list $pretty_name
	lappend key_list $module_key
    }

    append html "
    <tr><th valign=top align=left>Module</th>
    <td>[ns_htmlselect -labels $name_list module_key $key_list]</td></tr>
    "
}

append html "
<tr><th valign=top align=left>Sort key</th>
<td><input type=text size=5 name=sort_key MAXLENGTH=22></td></tr>
"

if { [string compare $type custom]==0 || [string compare $type static]==0 } {
    # visibility and registration enforcment apply only to the static and custom sections
    append html "
    <tr><th valign=top align=left>Requires registration?</th>
    <td>[ns_htmlselect -labels {Yes No} requires_registration_p {t f} f]</td></tr>
    
    <tr><th valign=top align=left>Visible to everybody?</th>
    <td>[ns_htmlselect -labels {Yes No} visibility {public private} public]</td></tr>
    "
}
    
append html "
<tr><th valign=top align=left>Introduction blurb</th>
<td><textarea name=intro_blurb cols=40 rows=8 wrap=soft></textarea></td></tr>

<tr><th valign=top align=left>Help blurb</th>
<td><textarea name=help_blurb cols=40 rows=8 wrap=soft></textarea></td></tr>

</table>

<p>
<center>
<input type=submit value=\"Add\">
</center>
</form>
<p>
"

ns_write "
$html
[ad_scope_admin_footer]
"


