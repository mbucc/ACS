# File:     /homepage/rmfile-1.tcl

ad_page_contract {
    Page to edit a file

    @param filesystem_node System variable to get us back where we started
    @param file_node File ID 

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Wed Jan 19 00:04:18 EST 2000
    @cvs-id edit-1.tcl,v 3.3.2.10 2000/09/22 01:38:16 kevin Exp
} {
    filesystem_node:notnull,naturalnum
    file_node:notnull,naturalnum
}

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]


# This query will return the quota of the user
set quota_qry "
select hp_true_filename(:file_node) as full_filename,
uf.file_size as old_filesize,
uf.filename as filename
from dual, users_files uf
where file_id=:file_node
"

db_1row select_user_quota $quota_qry

set access_denied_p [db_string select_access_denied_p "
select hp_access_denied_p(:file_node,:user_id) from dual"]

# And off with the handle!
db_release_unused_handles

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_returnredirect "dialog-class?title=Error!&text=File cannot be deleted<br>The filesystem has gone out of sync<br>Please contact your administrator.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
    #ad_return_error "Unable to Edit File" "Unauthorized Access to the FileSystem"
    #return
}

set title "Edit File - $filename"

set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "index?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>
"

set file_full_name "[ad_parameter ContentRoot users]$full_filename"

set streamhandle1 [open "$file_full_name" r]
set file_contents [read -nonewline $streamhandle1]

append page_content "
<form method=post action=edit-2>
  [export_form_vars filesystem_node file_node]
  <p>
  <table cellpadding=4>
    <tr>
      <td align=left>File Contents:</td>
    <tr>
      <td><textarea name=file_contents cols=70 rows=24 wrap=soft>[ns_quotehtml $file_contents]</textarea></td>
  </table>
  <input type=submit value=\"Save It!\">
</form>
</blockquote>
[ad_footer]
"

# Return the page for viewing
doc_return  200 text/html $page_content

