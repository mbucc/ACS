# /www/search/advanced-search.tcl

ad_page_contract {
    Sets search preferences

    @author phong@arsdigita.com
    @creation-date 2000-08-01
    @cvs-id advanced-search.tcl,v 1.1.2.2 2000/09/22 01:39:16 kevin Exp
} { 
    { query_string "" }
}

# get user search preferences
set display [ad_get_client_property -browser t -default "one_list" "search" "display_by_section_or_one_list"]
set num_results [ad_get_client_property -browser t -default "50" "search" "num_of_results_to_display"]

# create sets for bt_mergepiece
set display_set [ns_set create]
ns_set put $display_set display $display
set num_results_set [ns_set create]
ns_set put $num_results_set num_results $num_results

# check if this user is authorized
set user_id [ad_verify_and_get_user_id]
set is_authorized_p [im_user_is_authorized_p $user_id]

# get a list of searchable tables for the user
set sql_query "select table_name, section_name from sws_properties"
if { !$is_authorized_p } { append sql_query " where public_p='t'" }
append sql_query " order by rank"

set table_widget ""
db_foreach get_table_names_for_widget $sql_query {
    append table_widget "<input checked type=checkbox name=sections value=\"$table_name\">$section_name<br>\n"
    if { $table_name == "wp_slides" } {
	append table_widget "(what's a <a href=\"/help/for-one-page?url=/wp/index.tcl\">Wimpy Point</a>?)<br>"
    }
}

# set the stuff to output
set page_content "
[ad_header "Advanced Search"]
<h2>Advanced Search</h2>
[ad_context_bar_ws_or_index [list "index" "Search"] "Advanced Search"]
<hr>

<form method=post action=\"advanced-search-2.tcl\">

1. Modify your search by searching different types of content:<br><br>
<blockquote>
$table_widget
</blockquote>

2. Set your results preferences:<br><br>
<blockquote>
[bt_mergepiece "<input type=radio name=display value=\"by_section\">Show results grouped by content type. (You will see the results grouped by static pages, user comments, discussion forums, etc.)<br>
                <input type=radio name=display value=\"one_list\">Show results as one list.<br>" $display_set]
<br>
Display
[bt_mergepiece "
<select name=num_results>
  <option value=\"20\">20</option>
  <option value=\"50\">50</option>
  <option value=\"100\">100</option>
  <option value=\"200\">200</option>
  <option value=\"all\">all</option>
</select>" $num_results_set]
results per page (or results per content type, if that option is selected above).
</blockquote>

3. Search [ad_system_name] <input type=text size=50 name=query_string value=\"$query_string\">
<input type=submit name=search value=\"Go\">
<blockquote>
<input checked type=checkbox name=save value=\"1\"> Save my preferences for next time.
</blockquote>

</form>
[ad_footer]
"

doc_return  200 text/html $page_content









