# $Id: add-adv-group.tcl,v 3.0 2000/02/06 02:46:08 ron Exp $
ns_return 200 text/html "
[ad_admin_header "Add a New Ad Group"]

<h2>New Ad Group</h2>

[ad_admin_context_bar [list "index.tcl" "AdServer"] "New Ad Group"]

<hr>

<FORM METHOD=POST action=add-adv-group-2.tcl>
<TABLE noborder>
<TR>
<td>Group Key <br>(no spaces, please!)</td><td><INPUT TYPE=text name=group_key></td></tr>
<tr>
<td>Group Pretty Name<br>(for your convenience)</td><td><INPUT type=text name=pretty_name></td></tr>
<tr>
<td>Rotation Method</td><td><SELECT name=rotation_method>
<option value=least-exposure-first>Least Exposure First
</select></td></tr>
</TABLE>

<P>
<center>
<INPUT TYPE=submit value=add>
</center>


</FORM>
<p>

[ad_admin_footer]
"
