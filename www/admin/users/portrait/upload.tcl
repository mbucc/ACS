# upload.tcl,v 1.1.2.4 2000/09/22 01:36:31 kevin Exp

ad_page_contract {
    @author philg@mit.edu
    @param user_id user whose portrait we are to manage.
    @cvs-id upload.tcl,v 1.1.2.4 2000/09/22 01:36:31 kevin Exp
} {
    user_id:naturalnum,notnull
}

ad_maybe_redirect_for_registration

set flag [db_0or1row admin_user_portrait_upload_get_user_info "select 
  first_names, 
  last_name
from users 
where user_id=:user_id"]

if {$flag == 0} {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

doc_return 200 text/html "[ad_header "Upload Portrait"]

<h2>Upload Portrait</h2>

[ad_admin_context_bar [list "/admin/users/" "Users"] [list "../one?[export_url_vars user_id]" "$first_names $last_name"] [list "index?[export_url_vars user_id]" "$first_names's Portrait"] "Upload a Portrait"]

<hr>

How would you like the world to see $first_names $last_name?

<p>

Upload your favorite file, a scanned JPEG or GIF, from your desktop
computer system (note that you can't refer to an image elsewhere on
the Internet; this image must be on your computer's hard drive).

<blockquote>
<form enctype=multipart/form-data method=POST action=\"upload-2\">
[export_form_vars user_id return_url]
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
