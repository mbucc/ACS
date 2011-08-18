# $Id: content-section-edit.tcl,v 3.0 2000/02/06 03:15:11 ron Exp $
# File:     /admin/content-sections/content-section-edit.tcl
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
#note that user_id is the user_id of the user who owns this module (when scope=user)
# section_key

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

if {[catch {set selection [ns_db 1row $db "
    select section_key, section_pretty_name, section_type, section_url_stub, sort_key, 
           requires_registration_p, visibility, intro_blurb, help_blurb, module_key ,
           decode(enabled_p, 't', 1, 0) as enabled_p
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

set page_title "Properties of $type_name $section_pretty_name"
ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Content Sections"] "Properties"]
<hr>
"

lappend section_options_list "
<a href=\"content-section-edit-1.tcl?[export_url_scope_vars section_key]\">edit</a>"

switch $scope {
    public {
	lappend section_options_list "
	<a href=\"toggle-enabled-p.tcl?[export_url_scope_vars section_key]\">[ad_decode $enabled_p 1 disable enable]</a>
	"
    }
    group {
	# if scope is group, let's see what is the level of module administration allowed by 
	# system administrator for this group. 
	set group_module_administration [database_to_tcl_string $db "
	select group_module_administration
	from user_group_types
	where group_type=user_group_group_type($group_id)"]

	if { $group_module_administration!="none" } {
	    lappend section_options_list "
	    <a href=\"toggle-enabled-p.tcl?[export_url_scope_vars section_key]\">[ad_decode $enabled_p 1 disable enable]</a>
	    "	    
	}

	if { $group_module_administration=="full" } {
	    lappend section_options_list "
	    <a href=\"remove-module.tcl?[export_url_scope_vars section_key]\">remove module</a>
	    "
	}
    }
}

append html "
([join $section_options_list " | "])
<p>
<table>
"

if { ([string compare $section_type admin]==0) || ([string compare $section_type system]==0) } {
    append html "
    <tr><th valign=top align=left>Module
    <td>[database_to_tcl_string $db "select pretty_name from acs_modules where module_key='[DoubleApos $module_key]'"]</td></tr>
    "
}


append html "
<tr><th valign=top align=left>Section key</th>
<TD>$section_key</TD></TR>

<tr><th valign=top align=left>Section pretty name</th>
<td>$section_pretty_name</td></tr>
"

if { [string compare $section_type static]==0 } {
    append html "
    <tr><th valign=top align=left>Section url stub</th>
    <TD>$section_url_stub</TD></TR>
    "
}

append html "
<tr>
<th valign=top align=left>Sort key</th>
<td>[ad_decode $sort_key "" none $sort_key]</td></tr>
"

if { [string compare $section_type static]==0 || [string compare $section_type custom]==0 } {
    append html "
    <tr><th valign=top align=left>Requires registration?</th>
    <td>[ad_decode $requires_registration_p f No Yes]</td></tr>
    
    <tr><th valign=top align=left>Visible to everybody?</th>
    <td>$visibility</td></tr>
    "
}

append html "
<tr>
<th valign=top align=left>Introduction blurb</th>
<td>[ad_decode $intro_blurb "" none [ns_quotehtml $intro_blurb]]</td>
</tr>

<tr>
<th valign=top align=left>Help blurb</th>
<td>[ad_decode $help_blurb "" none [ns_quotehtml $help_blurb]]</td>
</tr>

</table>
<p>
"

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"







