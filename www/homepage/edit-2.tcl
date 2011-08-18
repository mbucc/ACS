# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:11:00 carsten Exp $
# File:     /homepage/mkfile-2.tcl
# Date:     Wed Jan 19 21:36:48 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create a new file

set_the_usual_form_variables
# filesystem_node, file_node, file_contents

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

# Deactivated code. Due to the new dialog-class
#if { ![info exists new_name] || [empty_string_p $new_name] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a filename"
#}

if { ![info exists filesystem_node] || [empty_string_p $filesystem_node] } {
    ad_return_error "FileSystem Node Information Missing"
}

if { ![info exists file_node] || [empty_string_p $file_node] } {
    ad_return_error "FileSystem Target Node Information Missing"
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

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_returnredirect "dialog-class.tcl?title=Error!&text=File cannot be deleted<br>The filesystem has gone out of sync<br>Please contact your administrator.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
    #ad_return_error "Unable to Edit File" "Unauthorized Access to the FileSystem"
    #return
}

set file_full_name "[ad_parameter ContentRoot users]$full_filename"

set streamhandle1 [open "$file_full_name" w]

if [catch {puts $streamhandle1 $file_contents} errmsg] {
    # directory already exists    
    append exception_text "
    <li>file $new_fullname could not be created."
    ad_return_complaint 1 $exception_text
    return
} else {
    flush $streamhandle1
    close $streamhandle1
    set new_size [file size $file_full_name]
    set dml_sql "
    update users_files
    set file_size=$new_size
    where file_id=$file_node
    "
    ns_db dml $db $dml_sql
}

# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node
