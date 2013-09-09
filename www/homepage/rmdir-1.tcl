# /homepage/rmfile-2.tcl

ad_page_contract {
    Allow to delete a directory.

    @param filesystem_node The top directory the directory will be deleted from.
    @param dir_node The directory to delete.

    @creation-date Jan 14 18:48:26 EST 2000
    @author mobin@mit.edu
    @cvs-id rmdir-1.tcl,v 3.2.2.4 2000/07/21 04:00:46 ron Exp

} {
    filesystem_node:notnull,naturalnum
    dir_node:notnull,naturalnum
}

# --------------------------- initialErrorCheck codeBlock ----

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

# This query will return the quota of the user

db_1row misc_info {
    select hp_get_filesystem_child_count(:dir_node) as child_count,
           hp_true_filename(:dir_node) as dir_name 
    from dual
}

set access_denied_p [db_string access_denied_p {
    select hp_access_denied_p(:dir_node,:user_id) from dual
}]

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
    db_dml dir_delete {
	delete from users_files
	where file_id=:dir_node
    }
}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node

