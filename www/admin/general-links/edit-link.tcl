# File: /admin/general-links/edit-link.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# Step 1 of 2 in editing a link
#
# $Id: edit-link.tcl,v 3.0 2000/02/06 03:23:43 ron Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_maybe_redirect_for_registration]

ad_page_variables {link_id {return_url "index.tcl"}}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select url, link_title, link_description, approved_p
from general_links
where link_id = $link_id"]


if { $selection == "" } {
   ad_return_error "Can't find link" "Can't find link $link_id"
   return
}

set_variables_after_query

set category_select [ad_categorization_widget -db $db -which_table "general_links" -what_id $link_id]

ns_db releasehandle $db

if {[empty_string_p $url]} {
    set url "http://"
}

set body "[ad_header "Edit Link" ]

<h2>Edit Link</h2>

[ad_admin_context_bar [list "$return_url" "General Links"] "Edit Link"]

<hr>

<blockquote>
<form action=edit-link-2.tcl method=post>

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
    append body "<input type=hidden name=category_id_list value=\"\">"
} else {
    append body "
    <tr>
    <th align=left valign=top>Associated Categories</th>
    <td valign=top>$category_select</td>
    </tr>
"
}

append body "
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

ns_return 200 text/html $body

