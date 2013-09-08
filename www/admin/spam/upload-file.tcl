# www/admin/spam/upload-file.tcl

ad_page_contract {

 Upload a message file to the spam drop zone
    @author hqm@arsdigita.com
    @cvs-id upload-file.tcl,v 3.3.2.4 2000/09/22 01:36:07 kevin Exp
} {
}

# assign necessary data for insert
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set originating_ip [ns_conn peeraddr]

append pagebody "[ad_admin_header "Upload Spam Message File to Drop Zone"]

<h2>Upload Spam File to Drop Zone</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "Upload Spam File to Drop Zone"]

<hr>

 <form enctype=multipart/form-data method=POST action=\"upload-file-2\">
<blockquote>
Upload a notification (spam) file to the drop zone at 
<i>[spam_file_location ""]</i>.<p>
 You may leave \"remote file\" blank below to
give the file the same name as it has on your local machine.
<p>

<table border=0>
<tr><th align=right> Local file:</th><td> <input name=clientfile type=file>
<br>
<font size=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".</font></td></tr>
<tr><th align=right> To remote file (in dropzone):</th><td> <INPUT TYPE=text NAME=path VALUE=\"\" SIZE=20></td></tr>
</table>
<center><input name=submit type=submit value=Upload></center>
</form>

</blockquote>
[ad_footer]
"


doc_return  200 text/html $pagebody

