# /homepage/move-2.tcl

ad_page_contract {
    Move a file or directory according to user's submission..

    @param filesystem_node The top directory the directory will be moved in.
    @param move_node The directory to move.
    @param move_target The directory to move into.
    
    @creation-date Jan 24 22:03:59 EST 2000
    @author mobin@mit.edu
    @cvs-id move-2.tcl,v 3.2.2.4 2000/07/21 04:00:44 ron Exp

} {
    filesystem_node:notnull,naturalnum
    move_node:notnull,naturalnum
    move_target:notnull,naturalnum
}

# --------------------------- initialErrorCheck codeBlock ----


# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

# This query will return the quota of the user
db_1row misc_info {
    select filename as old_name,
           hp_true_filename(:filesystem_node) as old_dir_name,
           hp_true_filename(:move_target) as new_dir_name,
           hp_true_filename(:move_node) as move_filename
    from users_files, dual
    where file_id=:move_node
}

set access_denied_p [db_string access_denied {
    select hp_access_denied_p(:move_node,:user_id) from dual
}]

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
    ad_returnredirect "dialog-class?title=Filesystem Management&text=A file with the name `$old_name'<br>already exists in the target directory.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return    
}

if [catch {ns_rename "$old_full_name" "$new_full_name"} errmsg] {
    # unable to rename
    append exception_text "
    <li>File $old_full_name could not be moved."
    ad_return_complaint 1 $exception_text
    return
} else {
    db_dml file_move {
	update users_files
	set parent_id=:move_target
	where file_id=:move_node
    }

}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index?filesystem_node=$filesystem_node

