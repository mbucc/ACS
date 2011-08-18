# $Id: add-adv.tcl,v 3.0 2000/02/06 02:46:08 ron Exp $
ReturnHeaders

set db [ns_db gethandle]

ns_write "[ad_admin_header "Add a new Ad"]

<h2>New Ad</h2>

[ad_admin_context_bar [list "index.tcl" "AdServer"] "New Ad"]

<hr>

<p>

<FORM METHOD=POST ACTION=add-adv-2.tcl>
<TABLE noborder>
<TR><td>Ad Key</td>
    <td><INPUT TYPE=text name=adv_key></td>
    <td>(no spaces please)</td>
</tr>
<tr><td>Link to:</td>
    <td><textarea name=target_url rows=4 cols=40>[ad_parameter DefaultTargetUrl adserver ""]</textarea></td>
    <td>(a URL for the user who clicks on this banner or all of doubleclick stuff)</td>
</tr>
<tr><td>Local Image:</td>
    <td><INPUT TYPE=radio CHECKED name=local_image_p value=\"t\">Yes <INPUT TYPE=radio name=local_image_p value=\"f\">No</td>
    <td>(Image resides on this server)</td>
</tr>
<tr><td>Track Clickthru:</td>
    <td><INPUT TYPE=radio CHECKED name=track_clickthru_p value=\"t\">Yes <INPUT TYPE=radio name=track_clickthru_p value=\"f\">No</td>
    <td>(No for doubleclick, etc.)</td>
</tr>
<tr><td>Image File Location:</td>
    <td><INPUT TYPE=text name=adv_filename size=30 value=\"[ad_parameter DefaultAd adserver ""]\"></td>
    <td>(pathname or URL of banner GIF, blank for doubleclick, etc.)</td>
</tr>
</table>
<br>
<center>
<INPUT TYPE=submit value=add>
</center>
</FORM>

[ad_admin_footer]
"
