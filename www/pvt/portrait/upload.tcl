# $Id: upload.tcl,v 3.1 2000/02/20 09:52:37 ron Exp $

set_form_variables 0

ad_maybe_redirect_for_registration

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select 
  first_names, 
  last_name
from users 
where user_id=$user_id"]

if [empty_string_p $selection] {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

set_variables_after_query

ns_return 200 text/html "[ad_header "Upload Portrait"]

<h2>Upload Portrait</h2>

[ad_context_bar_ws [list "index.tcl" "Your Portrait"] "Upload Portrait"]

<hr>

How would you like the world to see $first_names $last_name?

<p>

Upload your favorite file, a scanned JPEG or GIF, from your desktop
computer system (note that you can't refer to an image elsewhere on
the Internet; this image must be on your computer's hard drive).

<blockquote>
<form enctype=multipart/form-data method=POST action=\"upload-2.tcl\">
[export_form_vars return_url]
<table>
<tr>
<td valign=top align=right>Filename: </td>
<td>
<input type=file name=upload_file size=20><br>
<font size=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".</font>
</td>
</tr>
<tr>
<td valign=top align=right>Story Behind Photo
<br>
<font size=-1>(optional)</font>
</td>
<td><textarea rows=6 cols=50 wrap=soft name=portrait_comment>
</textarea>
</td>
</tr>

</table>
<p>
<center>
<input type=submit value=\"Upload\">
</center>
</blockquote>
</form>




[ad_footer]
"
