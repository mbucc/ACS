# /www/admin/content-sections/content-section-view.tcl
ad_page_contract {
    Shows the properties of the content section

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  tarik@arsdigita.com
    @creation-date    22/12/99
    @cvs-id content-section-view.tcl,v 3.1.6.7 2000/09/22 01:34:34 kevin Exp

    @param section_key
} {
    section_key:notnull
}


if { ![info exist scope] } {
    set scope public
}


db_1row content_get_section_info "
select section_pretty_name, type, section_url_stub, requires_registration_p, 
 decode (sort_key, NULL, 'N/A', sort_key) as sort_key, 
 decode (intro_blurb, NULL, 'N/A', intro_blurb) as intro_blurb, 
 decode (help_blurb, NULL, 'N/A', help_blurb) as help_blurb 
 from content_sections_temp 
 where [ad_scope_sql] and section_key = :section_key"


set page_body "
[ad_admin_header "View the entry for $section_pretty_name"]

<h2>View the entry for $section_pretty_name</h2>

[ad_admin_context_bar [list "index" "Content sections"] "View a content section"]

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
<li><a href=\"content-section-edit?[export_url_vars section_key]\">Edit the data for $section_pretty_name</a><br>
</ul>
<p>
"
db_release_unused_handles

append page_body "
$html
[ad_admin_footer]
"

doc_return  200 text/html $page_body

