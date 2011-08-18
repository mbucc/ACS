#
# /bookmarks/create-folder.tcl
#
# create a folder to store bookmarks in
#
# by aure@arsdigita.com and dh@arsdigita.com, June 199
#
# $Id: create-folder.tcl,v 3.0.4.2 2000/03/16 03:09:50 tina Exp $
#

ad_page_variables {return_url}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set bookmark_id [database_to_tcl_string $db "
    select bm_bookmark_id_seq.nextval from dual"]

set title "Create Folder"

set page_content "
[ad_header "$title"]

<h2>$title</h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $title]

<hr>
<form action=create-folder-2 method=post>
[export_form_vars bookmark_id return_url]

<table>
<tr>
  <td valign=top align=right>Input Folder Name:</td>
  <td><input name=local_title></td>
</tr>
<tr>
  <td valign=top align=right>Place in folder:  
  <img border=0 src=pics/ftv2folderopen align=top></td>
  <td>[bm_folder_selection $db $user_id $bookmark_id]</td>
</tr>
<tr>
  <td></td>
  <td><input type=submit value=Submit></td>
</form>
</tr>
</table>

[bm_footer]"

# Release the database handle
ns_db releasehandle $db

# serve the page
ns_return 200 text/html $page_content







