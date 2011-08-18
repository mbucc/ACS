# $Id: edit-1.tcl,v 3.0.4.1 2000/04/28 15:11:00 carsten Exp $
# File:     /homepage/rmfile-1.tcl
# Date:     Wed Jan 19 00:04:18 EST 2000
# Location: 42°21'N 71°04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to delete a file

set_the_usual_form_variables
# filesystem_node, file_node

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

if { ![info exists file_node] || [empty_string_p $file_node] } {
    ad_return_error "FileSystem Target Node for editing Missing."
    return
}

if { ![info exists filesystem_node] || [empty_string_p $filesystem_node] } {
    ad_return_error "FileSystem Node Information Missing"
    return
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
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

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

# Checking for site-wide administration status
set admin_p [ad_administrator_p $db $user_id]

# This query will return the quota of the user
set sql "
select hp_true_filename($file_node) as full_filename,
uf.file_size as old_filesize,
uf.filename as filename
from dual, users_files uf
where file_id=$file_node
"

# Extract results from the query
set selection [ns_db 1row $db $sql]

# This will  assign the  variables their appropriate values 
# based on the query.
set_variables_after_query

set access_denied_p [database_to_tcl_string $db "
select hp_access_denied_p($file_node,$user_id) from dual"]

# And off with the handle!
ns_db releasehandle $db

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_returnredirect "dialog-class.tcl?title=Error!&text=File cannot be deleted<br>The filesystem has gone out of sync<br>Please contact your administrator.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
    #ad_return_error "Unable to Edit File" "Unauthorized Access to the FileSystem"
    #return
}

ReturnHeaders

set title "Edit File - $filename"

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>
"

set file_full_name "[ad_parameter ContentRoot users]$full_filename"

set streamhandle1 [open "$file_full_name" r]
set file_contents [read -nonewline $streamhandle1]

append html "
<form method=post action=edit-2.tcl>
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
"





#if [catch {file delete "$file_full_name"} errmsg] {
#    append exception_text "
#    <li>File $file_full_name could not be deleted.<br>
#    $errmsg"
#    ad_return_complaint 1 $exception_text
#    return
#} else {
#    set dml_sql "
#    delete from users_files
#    where file_id=$file_node
#    "
#    ns_db dml $db $dml_sql
#}

ns_write "
$html
</blockquote>
[ad_footer]
"


