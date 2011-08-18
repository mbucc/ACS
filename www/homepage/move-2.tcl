# $Id: move-2.tcl,v 3.0.4.1 2000/04/28 15:11:02 carsten Exp $
# File:     /homepage/move-2.tcl
# Date:     Mon Jan 24 22:03:59 EST 2000
# Location: 42°21'N 71°04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to rename a file

set_the_usual_form_variables
# filesystem_node, move_node, move_target

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

if { ![info exists move_node] || [empty_string_p $move_node] } {
    ad_return_error "FileSystem Node for move Missing."
    return
}

if { ![info exists move_target] || [empty_string_p $move_target] } {
    ad_return_error "FileSystem Node for move target Missing."
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
select filename as old_name,
hp_true_filename($filesystem_node) as old_dir_name,
hp_true_filename($move_target) as new_dir_name,
hp_true_filename($move_node) as move_filename
from users_files, dual
where file_id=$move_node
"

# Extract results from the query
set selection [ns_db 1row $db $sql]

# This will  assign the  variables their appropriate values 
# based on the query.
set_variables_after_query

set access_denied_p [database_to_tcl_string $db "
select hp_access_denied_p($move_node,$user_id) from dual"]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Rename Filesystem Node" "Unauthorized Access to the FileSystem"
    return
}


set old_full_name "[ad_parameter ContentRoot users]$move_filename"
set new_full_name "[ad_parameter ContentRoot users]$new_dir_name/$old_name"

if {[file exists $new_full_name]} {
    ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=A file with the name `$old_name'<br>already exists in the target directory.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return    
}

if [catch {ns_rename "$old_full_name" "$new_full_name"} errmsg] {
    # unable to rename
    append exception_text "
    <li>File $old_full_name could not be moved."
    ad_return_complaint 1 $exception_text
    return
} else {
    set dml_sql "
    update users_files
    set parent_id=$move_target
    where file_id=$move_node
    "
    ns_db dml $db $dml_sql
}

# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node








