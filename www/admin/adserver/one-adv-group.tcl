# /www/admin/adserver/one-adv-group.tcl

ad_page_contract {
    @param group_key:notnull
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id one-adv-group.tcl,v 3.1.6.3 2000/07/21 03:56:00 ron Exp
} {
    group_key:notnull
}

set selection [ns_set create]

db_1row adv_group_info_query "
select group_key, 
       pretty_name
from   adv_groups 
where  group_key = :group_key" -column_set selection

set pretty_name [ns_set get $selection pretty_name]

set page_title "one ad group - $pretty_name"

set page_content "
[ad_admin_header $page_title]

<h2>$pretty_name</h2>

[ad_admin_context_bar [list "" AdServer] $page_title]

<hr>
"

set current_method [db_string r_method "
select rotation_method as current_method
from   adv_groups 
where  group_key = :group_key" -default ""]

set current_method [string trim $current_method]

set form "
<FORM METHOD=POST action=update-adv-group>
[export_form_vars group_key]
<TABLE noborder>
<TR>
<th align=right>Group Key</th>
<td>$group_key</td>
</tr>
<tr>
<th align=right>Group Pretty Name<br>(for your convenience)</th>
<td><INPUT type=text name=pretty_name size=40 value=\"$pretty_name\">
</tr>
<tr>
<th align=right>Rotation Method</th>
<td>
<select name=rotation_method>
[ad_generic_optionlist \
	{"Least Exposure First" "Random"} \
	{"least-exposure-first" "random"} $current_method]
</select>
</td>
</tr>

<tr>
<td></td>
<td><INPUT TYPE=submit value=update></td>
</tr>
</TABLE>
</FORM>
"

# append page_content "[bt_mergepiece $form $selection]

append page_content "
<p> 

$form

<h3>Ads in this Group</h3>

These are listed in the order that they will be displayed to users.

<ul>
"

set sql_query "
select adv_key 
from   adv_group_map 
where  group_key = :group_key 
order  by upper(adv_key)"

db_foreach adv_select_query $sql_query {
    append page_content "
    <li> <a href=\"one-adv?adv_key=$adv_key\">$adv_key</a> &nbsp;&nbsp; 
    (<a href=\"remove-adv-from-group?[export_url_vars group_key adv_key]\">remove</a>)\n"
}

append page_content "
<p>

<li> <A href=\"add-adv-to-group?[export_url_vars group_key]\">Add</a> an Ad To this Group

</ul>
<p>
[ad_admin_footer]
"

doc_return 200 text/html $page_content


