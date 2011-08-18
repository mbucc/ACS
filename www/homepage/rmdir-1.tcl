# $Id: rmdir-1.tcl,v 3.0.4.1 2000/04/28 15:11:03 carsten Exp $
# File:     /homepage/rmdir-1.tcl
# Date:     Fri Jan 14 18:48:26 EST 2000
# Location: 42°21'N 71°04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to delete a folder

set_the_usual_form_variables
# filesystem_node, dir_node

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

if { ![info exists dir_node] || [empty_string_p $dir_node] } {
    ad_return_error "FileSystem Target Node for deletion Missing."
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
select hp_get_filesystem_child_count($dir_node) as child_count,
       hp_true_filename($dir_node) as dir_name 
from dual
"

# Extract results from the query
set selection [ns_db 1row $db $sql]

# This will  assign the  variables their appropriate values 
# based on the query.
set_variables_after_query

set access_denied_p [database_to_tcl_string $db "
select hp_access_denied_p($dir_node,$user_id) from dual"]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Delete Folder" "Unauthorized Access to the FileSystem"
    return
}

if {$child_count != 0} {
    
    ad_returnredirect "dialog-class.tcl?title=Error!&text=Folder cannot be deleted<br>It is not empty&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
    
    # Old code before th generic dialog box days. deactivated by mobin
    # ad_return_complaint 1 "<li>Folder cannot be deleted. It is not empty."
    # return
}

set dir_full_name "[ad_parameter ContentRoot users]$dir_name"

if [catch {ns_rmdir "$dir_full_name"} errmsg] {
    # directory already exists    
    append exception_text "
    <li>Folder $dir_full_name could not be deleted. Make sure it is empty."
    ad_return_complaint 1 $exception_text
    return
} else {
    set dml_sql "
    delete from users_files
    where file_id=$dir_node
    "
    ns_db dml $db $dml_sql
}

# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node




