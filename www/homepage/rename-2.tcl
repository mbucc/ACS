# /homepage/rename-2.tcl

ad_page_contract {
    Update the name and description of a file according to user's submission.

    @param filesystem_node The top directory the file will be renamed in.
    @param rename_node The file to rename.
    @param new_name The new name for the file.
    @param new_desc The new description for the file.

    @creation-date Jan 14 18:48:26 EST 2000
    @author mobin@mit.edu
    @cvs-id rename-2.tcl,v 3.2.2.5 2000/07/21 22:05:55 mdetting Exp

} {
    filesystem_node:notnull,naturalnum
    rename_node:notnull,naturalnum
    new_name:notnull
    new_desc:notnull
}

# --------------------------- initialErrorCheck codeBlock ----
#  if { ![exists_and_not_null new_name] } {
#      ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to rename the requested file.<br>New name not provided.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

if {[regexp {.*/.*} $new_name match]} {
    ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to rename the requested file.<br>This operation is not for moving files.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*\.\..*} $new_name match]} {
    ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to rename the requested file.<br>This operation is not for moving files.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

# This query will return the quota of the user
db_1row misc_info {
    select filename as old_name,
    hp_true_filename(:filesystem_node) as dir_name
    from users_files, dual
    where file_id=:rename_node
}

set access_denied_p [db_string access_denied_p {
    select hp_access_denied_p(:rename_node,:user_id) from dual
}]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Rename Filesystem Node" "Unauthorized Access to the FileSystem"
    return
}

set old_full_name "[ad_parameter ContentRoot users]$dir_name/$old_name"
set new_full_name "[ad_parameter ContentRoot users]$dir_name/$new_name"

if {[file exists $new_full_name] && $old_name != $new_name} {
    ad_returnredirect "dialog-class?title=Filesystem Management&text=A file with the name `$new_name'<br>already exists in the current directory.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return    
}

if [catch {ns_rename "$old_full_name" "$new_full_name"} errmsg] {
    # unable to rename
    append exception_text "
    <li>Folder $old_full_name could not be renamed."
    ad_return_complaint 1 $exception_text
    return
} else {
    db_dml file_rename {
	update users_files
	set filename=:new_name,
	file_pretty_name=:new_desc
	where file_id=:rename_node
    }
}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index?filesystem_node=$filesystem_node


