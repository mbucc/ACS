# /www/admin/adserver/add-adv.tcl

ad_page_contract {
    @param none
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id add-adv.tcl,v 3.1.6.6 2000/11/20 23:55:16 ron Exp
}

doc_return 200 text/html "[ad_admin_header "Add a new Ad"]

<h2>New Ad</h2>

[ad_admin_context_bar [list "" "AdServer"] "New Ad"]

<hr>

<p>

<FORM METHOD=POST ACTION=add-adv-2>
<TABLE noborder>
<TR><th align=right>Ad Key:</th>
    <td><INPUT TYPE=text name=adv_key></td>
    <td>(no spaces please)</td>
</tr>
<tr><th align=right>Link to:</th>
    <td><textarea name=target_url rows=4 cols=40>[ad_parameter DefaultTargetUrl adserver ""]</textarea></td>
    <td>(a URL for the user who clicks on this banner or all of doubleclick stuff)</td>
</tr>
<tr><th align=right>Track Clickthru:</th>
    <td><INPUT TYPE=radio CHECKED name=track_clickthru_p value=\"t\">Yes <INPUT TYPE=radio name=track_clickthru_p value=\"f\">No</td>
    <td>(No for doubleclick, etc.)</td>
</tr>
<tr><th align=right>Local Image:</th>
    <td><INPUT TYPE=radio CHECKED name=local_image_p value=\"t\">Yes <INPUT TYPE=radio name=local_image_p value=\"f\">No</td>
    <td>(Image resides on this server)</td>
</tr>
<tr><th align=right>Image File Location:</th>
    <td><INPUT TYPE=text name=adv_filename size=30 value=\"[ad_parameter DefaultAd adserver ""]\"></td>
    <td>(pathname or URL of banner GIF, blank for doubleclick, etc.)</td>
</tr>
<tr>
<td></td>
<td><INPUT TYPE=submit value=add></td>
</tr>

</table>
</FORM>

<p>

<h3>Note</h3>

<p>If the graphic for your advertisement is not on the server yet, you can use the 

<a href=/admin/file-manager/>file-manger</a>

to upload it to the <b>ads</b> directory.</p>  

[ad_admin_footer]
"

