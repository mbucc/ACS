# File:     /homepage/mkfile-2.tcl

ad_page_contract {
    Page to make edits real

    @param filesystem_node System variable to get us back to the start
    @param file_node File ID
    @param file_contents File's new contents

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Wed Jan 19 21:36:48 EST 2000
    @cvs-id edit-2.tcl,v 3.2.2.12 2000/07/21 04:00:41 ron Exp
} {
    filesystem_node:notnull,naturalnum
    file_node:notnull,naturalnum
    file_contents:allhtml
}

# --------------------------- initialErrorCheck codeBlock ----

# set exception_count 0
set exception_text ""

# Deactivated code. Due to the new dialog-class
#if { ![info exists new_name] || [empty_string_p $new_name] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a filename"
#}

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
set user_quota_qry "
select hp_true_filename(:file_node) as full_filename,
uf.file_size as old_filesize,
uf.filename as filename
from dual, users_files uf
where file_id=:file_node
"

db_1row select_user_quota $user_quota_qry

set access_denied_p [db_string select_access "
select hp_access_denied_p(:file_node,:user_id) from dual"]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_returnredirect "dialog-class?title=Error!&text=File cannot be deleted<br>The filesystem has gone out of sync<br>Please contact your administrator.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
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
    set file_size=:new_size
    where file_id=:file_node
    "
    db_dml update_user_file $dml_sql
}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index?filesystem_node=$filesystem_node


