# $Id: edit-ad-4.tcl,v 3.1.2.1 2000/04/28 15:10:31 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# classified_ad_id

set auth_user_id [ad_verify_and_get_user_id]

if { $auth_user_id == 0 } {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/edit-ad-4.tcl?[export_url_vars classified_ad_id]]
}


set db [gc_db_gethandle]
set selection [ns_db 0or1row $db "select ca.*, to_char(expires,'YYYY-MM-DD') as ansi_expires
from classified_ads ca
where classified_ad_id = $classified_ad_id"]

if { $selection == "" } {
    ad_return_error "Could not find Ad $classified_ad_id" "in <a href=index.tcl>[gc_system_name]</a>

<p>

Either you are fooling around with the Location field in your browser
or my code has a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"
       return 
}

# OK, we found the ad in the database if we are here...
# the variable SELECTION holds the values from the db
set_variables_after_query

# we use subquery because we have to hold the seletion to make the form with bt_mergepiece
set sub_selection [ns_db 1row $db [gc_query_for_domain_info $domain_id "insert_form_fragments,ad_deletion_blurb,"]]
set_variables_after_subquery


#check to see the user has the correct authentication cookie

if { $auth_user_id != $user_id } {
    ad_return_error "Unauthorized" "You are not authorized to edit this ad."
    return
}

# OK, the response from the user matched
# the variable SELECTION still holds the values from the db


set raw_form "<form method=post action=edit-ad-5.tcl>
<input type=hidden name=classified_ad_id value=$classified_ad_id>
<input type=hidden name=user_id value=$user_id>

<table>"


if { [string first "one_line" $insert_form_fragments] == -1 } {
	append raw_form "<tr><th align=left>One Line Summary<br>
<td><input type=text name=one_line size=50 value=\"[philg_quote_double_quotes $one_line]\">
</tr>
"
}

if { [string first "full_ad" $insert_form_fragments] == -1 } {
	append raw_form "<tr><th align=left>Full Ad<br>
<td><textarea name=full_ad wrap=hard rows=6 cols=50>[philg_quote_double_quotes $full_ad]</textarea>
</tr>
<tr><th align=left>Text above is
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
"
}



append raw_form "$insert_form_fragments
"


set selection_without_nulls [remove_nulls_from_ns_set $selection]

set final_form [bt_mergepiece $raw_form $selection_without_nulls]

ReturnHeaders
append html "[gc_header "Edit \"$one_line\""]

<h2>Edit \"$one_line\"</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Edit Ad #$classified_ad_id"]

<hr>

<p>
$final_form
"

if {$geocentric_p == "t"} {
    append html "<tr><th>State<td>
    [state_widget $db $state "state"] 
    <tr><th>Country<td>
    [country_widget $db $country "country"]"
}

append html "<tr><th>Expires<td>
<input name=expires type=text size=11 value=\"$ansi_expires\">  YYYY-MM-DD \[format must be exact\]
<tr><th>Category<td>
<select name=primary_category>
[db_html_select_options $db "select primary_category
from ad_categories
where domain_id = $domain_id
order by primary_category" $primary_category]
</select>
</table>
<p>

<center>

<input type=submit value=\"Update Ad\">

</center>

</form>
[gc_footer $maintainer_email]"

ns_write $html
