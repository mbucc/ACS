# File: /general-links/link-add-without-assoc-2.tcl

ad_page_contract {
    Step 2 of 4 in adding link WITHOUT association.
    @param return_url the URL to go back to
    @param link_title the title of the URL
    @param url the URL to link
    
    @author tzumainn@arsdigita.com 
    @creation-date 1 February 2000
    @cvs-id link-add-without-assoc-2.tcl,v 3.2.2.6 2001/01/10 21:07:36 khy Exp

} {
    return_url:notnull
    {link_title ""} 
    url:notnull
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


page_validation {
    if { $url == "http://"} {
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


set link_id [db_string select_next_link_id "select general_link_id_sequence.nextval from dual"]

set category_select [ad_categorization_widget -which_table "general_links" -what_id $link_id]

db_release_unused_handles

set whole_page "
[ad_header "Add \"$link_title\" (Step 2 of 3)"]

<h2>Add \"$link_title\" (Step 2 of 3)</h2>

[ad_context_bar_ws [list $return_url "General Links"] "Add \"$link_title\" (Step 2 of 3)"]

<hr>

<blockquote>
<form action=link-add-without-assoc-3 method=post>
[export_form_vars return_url url]
[export_form_vars -sign link_id]
<table>

<tr>
<th align=right>URL:</th>
<td>$url</td>
</tr>

<tr>
<th align=right>Link Title:</th>
<td><input type=text name=link_title size=50 maxlength=100 value=\"$link_title\"></td>
</tr>

<tr>
<th align=right valign=top>Link Description:</th>
<td valign=top><textarea name=link_description cols=40 rows=5 wrap=soft></textarea></td>
</tr>
"

if {[regexp {option} $category_select match] == 0} {
    append whole_page "<input type=hidden name=category_id_list value=\"\">"
} else {
    append whole_page "
    <tr>
    <th align=right valign=top>Associated Categories:</th>
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

