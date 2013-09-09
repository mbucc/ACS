# /homepage/rmfile-1.tcl

ad_page_contract {
    Allow to delete a file from the directory.

    @param filesystem_node The directory the file will be deleted from.
    @param file_node The file to delete.

    @creation-date Jan 14 18:48:26 EST 2000
    @author mobin@mit.edu
    @cvs-id rmfile-1.tcl,v 3.3.2.4 2000/07/21 04:00:46 ron Exp

} {
    filesystem_node:notnull,naturalnum
    file_node:notnull,naturalnum
}

# --------------------------- initialErrorCheck codeBlock ----


# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

# This query will return the quota of the user

set sql {
    select hp_get_filesystem_child_count(:file_node) as child_count,
           hp_true_filename(:file_node) as full_filename 
    from dual
}

db_1row misc_info $sql 

set access_denied_p [db_string access_denied_p {
    select hp_access_denied_p(:file_node,:user_id) from dual
}]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Delete File" "Unauthorized Access to the FileSystem"
    return
}

if {$child_count != 0} {
    # Files contained within this file! There has to be something awfully wrong
    # with this file.
    ad_returnredirect "dialog-class.tcl?title=Error!&text=File cannot be deleted<br>The filesystem has gone out of sync<br>Please contact your administrator.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
    
    # Old code before th generic dialog box days. deactivated by mobin
    # ad_return_complaint 1 "<li>File cannot be deleted. It is crazy."
    # return
}

set file_full_name "[ad_parameter ContentRoot users]$full_filename"

db_dml file_delete {
delete from users_files
where file_id=:file_node
} 

db_release_unused_handles

if [catch {file delete "$file_full_name"} errmsg] {
    if [catch {exec rm $file_full_name} errmsg2] {
	append exception_text "
	<li>File $file_full_name could not be deleted.<br>
	$errmsg2"
	ad_return_complaint 1 $exception_text
	return    
    } else {
	ad_returnredirect index.tcl?filesystem_node=$filesystem_node
	return
    }
    append exception_text "
    <li>File $file_full_name could not be deleted.<br>
    $errmsg"
    ad_return_complaint 1 $exception_text
    return
} 

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node

