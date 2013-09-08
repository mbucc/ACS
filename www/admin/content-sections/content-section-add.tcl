# /www/admin/content-sections/content-section-add.tcl
ad_page_contract {
    Adding a content section

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  tarik@arsdigita.com
    @creation-date  22/12/99
    @cvs-id content-section-add.tcl,v 3.2.2.9 2001/01/10 17:16:14 khy Exp

    @param type

} {
    {type static}
}


ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set section_id [db_string get_next_content_section_id "select content_section_id_sequence.nextval from dual"]

# type is (static|module|custom), anything else is silently changed to static
switch $type {
    default
           -
    static {
	set page_title "Add Static Section"
	set type "static"
    }
    module {
	set page_title "Add Module"
    }
    custom {
	set page_title "Add Custom Section"
    }
}

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index" "Content Sections"] $page_title]
<hr>
"

append html "
<form method=post action=\"content-section-add-2\"> 
[export_form_vars -sign section_id]

<table>
<tr><th valign=top align=left>Section key</th>
<td><input type=text size=20 name=section_key MAXLENGTH=30></td></tr>

<tr><th valign=top align=left>Section pretty name</th>
<td><input type=text size=40 name=section_pretty_name MAXLENGTH=200></td></tr>
"

switch $type {
    static {
	set section_type static
	append html "
	[export_form_vars section_type ]
	<tr><th valign=top align=left>Section url stub</th>
	<td><input type=text size=40 name=section_url_stub MAXLENGTH=200></td></tr>
	"
    }
    custom {
	set section_type custom
	append html "
	[export_form_vars section_type]
	"
    }
    module {
	set query_sql "
	select module_key, pretty_name 
	from acs_modules
	where supports_scoping_p='t'
	and module_key not in (select module_key
	                       from content_sections
                               where [ad_scope_sql]
                               and (section_type='system' or section_type='admin'))
	"
	db_foreach select_query $query_sql  {
	    lappend name_list $pretty_name
	    lappend key_list $module_key
	}

	append html "
	<tr><th valign=top align=left>Module</th>
	<td>[ns_htmlselect -labels $name_list module_key $key_list]</td></tr>
	"
    }
}

db_release_unused_handles

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

append page_body "
$html
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_body
