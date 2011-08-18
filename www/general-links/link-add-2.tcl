# $Id: link-add-2.tcl,v 3.0 2000/02/06 03:44:17 ron Exp $
# File: /general-links/link-add-2.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  Step 2 of 4 in adding link and its association
#
# $Id: link-add-2.tcl,v 3.0 2000/02/06 03:44:17 ron Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_page_variables {on_which_table on_what_id item {module ""} return_url {link_title ""} url}

page_validation {
    if {[empty_string_p $url] || $url == "http://"} {
	error "You did not enter a URL.  Examples of valid URLs include:
	<ul>
	<li> http://arsdigita.com
	<li> http://photo.net/photo
	</ul>
	"
    }
}

#check for the user cookie
set user_id [ad_maybe_redirect_for_registration]

# if link_title is empty, look for title on page
if {[empty_string_p $link_title]} {
    set link_title [ad_general_link_get_title $url]
    if {[empty_string_p $link_title]} {
	set link_title "-- title not found --"
    }
}

set db [ns_db gethandle]

set link_id [database_to_tcl_string $db "select general_link_id_sequence.nextval from dual"]
set association_id [database_to_tcl_string $db "select general_link_map_id.nextval from dual"]

set category_select [ad_categorization_widget -db $db -which_table "general_links" -what_id $link_id]

ns_db releasehandle $db

set whole_page "
[ad_header "Add \"$link_title\" to $item (Step 2 of 3)"]

<h2>Add \"$link_title\" to $item (Step 2 of 3)</h2>

[ad_context_bar_ws [list $return_url $item] "Add \"$link_title\" to $item (Step 2 of 3)"]

<hr>

<blockquote>
<form action=link-add-3.tcl method=post>
[export_form_vars on_which_table on_what_id item return_url module link_id association_id url]

<table>

<tr>
<th align=left>URL:</th>
<td>$url</td>
</tr>

<tr>
<th align=left>Link Title:</th>
<td><input type=text name=link_title size=50 maxlength=100 value=\"$link_title\"></td>
</tr>

<tr>
<th align=left valign=top>Link Description:</th>
<td valign=top><textarea name=link_description cols=40 rows=5 wrap=soft></textarea></td>
</tr>
"

if {[regexp {option} $category_select match] == 0} {
    append whole_page "<input type=hidden name=category_id_list value=\"\">"
} else {
    append whole_page "
    <tr>
    <th align=left valign=top>Associated Categories:</th>
    <td valign=top>$category_select</td>
    </tr>
"
}

append whole_page "
</table>

</blockquote>
<br>
<center>
<input type=submit name=submit value=\"Proceed to Step 3\">
</center>
</form>
[ad_footer]
"

ns_return 200 text/html $whole_page



