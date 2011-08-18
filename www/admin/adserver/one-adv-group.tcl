# $Id: one-adv-group.tcl,v 3.0 2000/02/06 02:46:10 ron Exp $
set_the_usual_form_variables
# group_key

set db [ns_db gethandle]

set selection [ns_db 1row $db "select group_key, pretty_name from adv_groups where group_key='$QQgroup_key'"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "One Ad Group - $pretty_name"]
<h2>$pretty_name</h2>
one of the <A href=\"all-adv-groups.tcl\">Ad Groups</a> at <A href=\"index.tcl\">Adserver</a>.
<hr><p>
"

set form "
<FORM METHOD=POST action=update-adv-group.tcl>
<TABLE noborder>
<TR>
<td>Group Key</td><td>$group_key</td>
[export_form_vars group_key]
</tr>
<tr>
<td>Group Pretty Name<br>(for your convenience)</td><td><INPUT type=text name=pretty_name size=40><INPUT TYPE=submit value=update></td></tr>
</TABLE>
</FORM>
"

ns_write "[bt_mergepiece $form $selection]
<p>
<h3>Ads in this Group</h3>

These are listed in the order that they will be displayed to users.

<ul>
"

set selection [ns_db select $db "select adv_key 
from adv_group_map
where group_key='$QQgroup_key'
order by upper(adv_key)"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    ns_write "<li> <a href=\"one-adv.tcl?adv_key=$adv_key\">$adv_key</a>
&nbsp;&nbsp; (<a href=\"remove-adv-from-group.tcl?[export_url_vars group_key adv_key]\">remove</a>)
\n" 
}

ns_write "<p>

<li> <A href=\"add-adv-to-group.tcl?group_key=$group_key\">Add</a> an Ad To this Group

</ul>
<p>
[ad_admin_footer]
"

