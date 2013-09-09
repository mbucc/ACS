# File: /general-links/link-add-2.tcl

ad_page_contract {
    Step 2 of 4 in adding link and its association.

    @param on_which_table the table to relate the link to
    @param on_what_id the id column on the table
    @param item the item name
    @param module the name of the module
    @param return_url the url to return to
    @param link_title a title for the link
    @param url the URL 

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 02/01/2000
    @cvs-id link-add-2.tcl,v 3.2.2.6 2001/01/10 21:03:44 khy Exp
} {
    on_which_table:notnull
    on_what_id:notnull
    item:notnull
    module:optional
    return_url:notnull
    link_title:optional
    url:notnull
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


page_validation {
    if {$url == "http://"} {
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



set link_id [db_string select_new_link_id "select general_link_id_sequence.nextval from dual"]

set association_id [db_string select_new_map_id "select general_link_map_id.nextval from dual"]

set category_select [ad_categorization_widget -which_table "general_links" -what_id $link_id]

db_release_unused_handles

set whole_page "
[ad_header "Add \"$link_title\" to $item (Step 2 of 3)"]

<h2>Add \"$link_title\" to $item (Step 2 of 3)</h2>

[ad_context_bar_ws [list $return_url $item] "Add \"$link_title\" to $item (Step 2 of 3)"]

<hr>

<blockquote>
<form action=link-add-3 method=post>
[export_form_vars on_which_table on_what_id item return_url module url]
[export_form_vars -sign link_id association_id]
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

doc_return  200 text/html $whole_page





