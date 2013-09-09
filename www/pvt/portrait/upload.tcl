# /www/pvt/portrait/upload.tcl

ad_page_contract {
    @cvs-id upload.tcl,v 3.3.2.4 2000/09/22 01:39:13 kevin Exp
}

set_form_variables 0

ad_maybe_redirect_for_registration

set user_id [ad_verify_and_get_user_id]

set row_exists_p [db_0or1row portrait_upload_exists_check "select 
  first_names, 
  last_name
from users 
where user_id=:user_id" -bind [ad_tcl_vars_to_ns_set user_id]]

if $row_exists_p==0 {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

db_release_unused_handles

doc_return  200 text/html "[ad_header "Upload Portrait"]

<h2>Upload Portrait</h2>

[ad_context_bar_ws [list "index.tcl" "Your Portrait"] "Upload Portrait"]

<hr>

How would you like the world to see $first_names $last_name?

<p>

Upload your favorite file, a scanned JPEG or GIF, from your desktop
computer system (note that you can't refer to an image elsewhere on
the Internet; this image must be on your computer's hard drive).

<blockquote>
<form enctype=multipart/form-data method=POST action=\"upload-2\">
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
