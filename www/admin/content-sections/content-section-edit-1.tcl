# /www/admin/content-sections/content-section-edit-1.tcl
ad_page_contract {
    Editing a content section

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  tarik@arsdigita.com
    @creation-date   22/12/99
    @cvs-id content-section-edit-1.tcl,v 3.2.2.7 2000/09/22 01:34:33 kevin Exp

    @param section_key
} {
    section_key:notnull
}

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

if {[catch {set selection [db_1row content_select_section_info "
    select section_key, section_pretty_name, section_type, section_url_stub, sort_key,
           requires_registration_p, visibility, intro_blurb, help_blurb, module_key
    from content_sections
    where [ad_scope_sql] and section_key=:section_key"]} errmsg]} {
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

db_release_unused_handles

# now we have the values from the database.

switch $section_type {
    admin {set type_name Module}
    system {set type_name Module}
    custom {set type_name "Custom Section"}
    static {set type_name "Static Section"}
}


set page_title "Edit $type_name $section_pretty_name"
set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index" "Content Sections"] [list "content-section-edit?[export_url_vars section_key]" "Property"] "Edit" ]
<hr>
"

append html "
<table>
"

if { ([string compare $section_type admin]==0) || ([string compare $section_type system]==0) } {
    append html "
    <tr><th valign=top align=left>Module
    <td>[db_string content_section_get_pretty_name "select pretty_name from acs_modules where module_key = :module_key"]</td></tr>
    "
}

append html "
<form method=POST action=content-section-edit-2>
[export_form_vars section_key section_type]

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



append page_body "
$html
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_body


