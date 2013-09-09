# /www/bookmarks/create-folder.tcl

ad_page_contract {
    create a folder to store bookmarks in
    @param return_url the url to return to 
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id create-folder.tcl,v 3.2.2.6 2001/01/09 22:45:11 khy Exp
} {
    return_url
}


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set bookmark_id [db_string bookmark_id "select bm_bookmark_id_seq.nextval from dual"]

set title "Create Folder"

set page_content "
[ad_header "$title"]

<h2>$title</h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $title]

<hr>
<form action=create-folder-2 method=post>
[export_form_vars -sign bookmark_id]
[export_form_vars return_url]

<table>
<tr>
  <td valign=top align=right>Input Folder Name:</td>
  <td><input name=local_title></td>
</tr>
<tr>
  <td valign=top align=right>Place in folder:  
  <img border=0 src=pics/ftv2folderopen align=top></td>
  <td>[bm_folder_selection $user_id $bookmark_id]</td>
</tr>
<tr>
  <td></td>
  <td><input type=submit value=Submit></td>
</form>
</tr>
</table>

[bm_footer]"

# Release the database handle
db_release_unused_handles

# serve the page
doc_return  200 text/html $page_content






