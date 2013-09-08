# /www/admin/adserver/add-adv-group.tcl

ad_page_contract {
    adds an adv group
    
    @param none
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id add-adv-group.tcl,v 3.2.2.2 2000/07/21 03:55:59 ron Exp
} {
    
}

doc_return 200 text/html "
[ad_admin_header "Add a New Ad Group"]

<h2>New Ad Group</h2>

[ad_admin_context_bar [list "" "AdServer"] "New Ad Group"]

<hr>

<FORM METHOD=POST action=add-adv-group-2>
<TABLE noborder>
<TR>
<td>Group Key <br>(no spaces, please!)</td><td><INPUT TYPE=text name=group_key></td></tr>
<tr>
<td>Group Pretty Name<br>(for your convenience)</td><td><INPUT type=text name=pretty_name></td></tr>
<tr>
<td>Rotation Method</td><td>
<SELECT name=rotation_method>
<option value=least-exposure-first>Least Exposure First
<option value=sequential>Sequential
<option value=random>Random
</select></td></tr>

<tr>
<td></td>
<td><input type=submit value=add></td>
</tr>

</TABLE>

</FORM>
<p>

[ad_admin_footer]
"


