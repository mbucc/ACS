# File: /admin/general-links/edit-link.tcl

ad_page_contract {
    Step 1 of 2 in editing a link

    @param link_id The ID of the link to edit
    @param return_url Where to go when finished editing

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id edit-link.tcl,v 3.2.2.6 2000/09/22 01:35:25 kevin Exp
} {
    link_id:notnull,naturalnum
    {return_url "index"}
}

#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_maybe_redirect_for_registration]

if {![db_0or1row select_one_link_info "select url, link_title, link_description, approved_p
from general_links
where link_id = :link_id"]} {
   ad_return_error "Can't find link" "Can't find link $link_id"
   return
}

set category_select [ad_categorization_widget -which_table "general_links" -what_id $link_id]

db_release_unused_handles

if {[empty_string_p $url]} {
    set url "http://"
}

set page_content "[ad_header "Edit Link" ]

<h2>Edit Link</h2>

[ad_admin_context_bar [list "$return_url" "General Links"] "Edit Link"]

<hr>

<blockquote>
<form action=edit-link-2 method=post>

<table>

<tr>
<th align=left>Link Title</th>
<td align=left><input type=text name=link_title value=\"$link_title\" size=50 maxlength=100></td>
</tr>

<tr>
<th align=left>URL</th>
<td align=left><input type=text name=url value=\"$url\" size=50 maxlength=300></td>
</tr>

<tr>
<th align=left valign=top>Link Description</th>
<td valign=top align=left><textarea name=link_description cols=40 rows=5 wrap=soft>$link_description</textarea></td>
</tr>
"

if {[regexp {option} $category_select match] == 0} {
    append page_content "<input type=hidden name=category_id_list value=\"\">"
} else {
    append page_content "
    <tr>
    <th align=left valign=top>Associated Categories</th>
    <td valign=top>$category_select</td>
    </tr>
"
}

append page_content "
<tr>
<th align=left>Approval status</th>
<td align=left><select name=approved_p>
 [ad_generic_optionlist {"Approved" "Unapproved"} {"t" "f"} $approved_p]
</select>
</td>
</tr>

</table>

<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars link_id return_url]
</form>
</blockquote>
[ad_footer]
"
#-- serve the page ------------

doc_return  200 text/html $page_content

