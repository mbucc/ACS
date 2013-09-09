# /www/admin/content-sections/content-section-edit.tcl
ad_page_contract {
    Editing a content section

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  tarik@arsdigita.com
    @creation-date   22/12/99 
    @cvs-id content-section-edit.tcl,v 3.2.2.8 2000/09/22 01:34:34 kevin Exp

    @param section_key

} {
    section_key:notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

if {[catch {set selection [db_1row content_get_section_info "
    select section_key, section_pretty_name, section_type, section_url_stub, sort_key, 
 requires_registration_p, visibility, intro_blurb, help_blurb, module_key, 
 decode (enabled_p, 't', 1, 0) as enabled_p 
 from content_sections 
 where [ad_scope_sql] and section_key = :section_key"]} errmsg]} {
    ad_scope_return_error "Error in finding the data" "We encountered an error in querying the database for your object.
Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
} 


# now we have the values from the database.

switch $section_type {
    admin {set type_name Module}
    system {set type_name Module}
    custom {set type_name "Custom Section"}
    static {set type_name "Static Section"}
}


set page_title "Properties of $type_name $section_pretty_name"
set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index" "Content Sections"] "Properties"]
<hr>
"

lappend section_options_list "
<a href=\"content-section-edit-1?[export_url_vars section_key]\">edit</a>"

switch $scope {
    public {
	lappend section_options_list "
	<a href=\"toggle-enabled-p?[export_url_vars section_key]\">[ad_decode $enabled_p 1 disable enable]</a>
	"
    }
    group {
	# if scope is group, let's see what is the level of module administration allowed by 
	# system administrator for this group. 
	set group_module_administration [db_string content_sections_group_module "
	select group_module_administration 
 from user_group_types 
 where group_type = user_group_group_type(:group_id)"]

	if { [string compare $group_module_administration "none"] != 0 } {
	    lappend section_options_list "
	    <a href=\"toggle-enabled-p?[export_url_vars section_key]\">[ad_decode $enabled_p 1 disable enable]</a>
	    "	    
	}

	if { [string compare $group_module_administration "full"] == 0 } {
	    lappend section_options_list "
	    <a href=\"remove-module?[export_url_vars section_key]\">remove module</a>
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
    <td>[db_string content_sections_get_pretty_name "select pretty_name from acs_modules where module_key = :module_key"]</td></tr>
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

append page_body "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"



doc_return  200 text/html $page_body
