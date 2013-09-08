# File:     /homepage/upload-2.tcl

ad_page_contract {
    Upload File form target

    @param filesystem_node System variable to tell us where to get back to
    @param upload_file Name of the new file
    @param new_node Determined in upload-1 as the new ID for the file
    
    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Tue Jan 18 23:08:52 EST 2000
    @cvs-id upload-2.tcl,v 3.2.6.10 2001/01/10 21:59:24 khy Exp
} {
    filesystem_node:notnull,naturalnum
    upload_file:notnull
    new_node:notnull,naturalnum,verify
}

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

# The following was scrubbed because it has a propietary error message;
# I guess it's up to Usman if he wants to keep his or just stick with
# what ad_page_contract says
#
# The exception_count and exception_text are used later; lots of errors
# sort of just get returned as they migh occur


# Now check to see if the input is good as directed by the page designer
set exception_count 0
set exception_text ""

#  if { ![info exists upload_file] || [empty_string_p $upload_file] } {
#      append exception_text "<li>Please specify a file to upload\n"
#      incr exception_count
    
#      ad_returnredirect "dialog-class?title=Error!&text=Cannot process your upload request.<br>You did not specify a filename to upload!&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

#  if {$exception_count > 0} {
#      ad_return_complaint $exception_count $exception_text
#      return
#  }



# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

set access_denied_p [db_string select_user_access "
select hp_access_denied_p(:filesystem_node,:user_id) from dual"]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Upload File" "Unauthorized Access to the FileSystem"
    return
}

set new_filename $upload_file
set tmp_filename [ns_queryget upload_file.tmpfile]

if {[regexp {.*\\([^\\]*)} $new_filename match windows_filename]} {
    set new_filename $windows_filename
}

set new_filesize [file size $tmp_filename]

set quota_left [db_string select_user_quota_left "
select hp_user_quota_left(:user_id, [ad_parameter NormalUserMaxQuota users], [ad_parameter PrivelegedUserMaxQuota users], :admin_p, [ad_parameter DirectorySpaceRequirement users]) from dual"]

if {$new_filesize > $quota_left} {
    ad_returnredirect "dialog-class?title=Quota Management System&text=You do not have enough quota space left to upload this file!&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

set dir_name [db_string select_dir_name "
select hp_true_filename(:filesystem_node) from dual"]

set new_full_filename "[ad_parameter ContentRoot users]$dir_name/$new_filename"


if {[file exists $new_full_filename]} {
    ad_returnredirect "dialog-class?title=Error!&text=A file with the name $new_filename<br>already exists in the current directory.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

set double_click_p [db_string select_double_click_p "
select count(*)
from users_files
where file_id = :new_node"]

if {$double_click_p == "0"} {
    # not a double click
    
    if [catch {ns_cp -preserve $tmp_filename $new_full_filename} errmsg ] {
	# file could not be copied	
	incr exception_count
	append exception_text "<li>File could not be copied into $new_full_filename <br>
	This is the error message it returned : $errmsg
	"
    } else {
	db_dml insert_user_file "
	insert into users_files
	 (file_id, filename,
	 directory_p, file_pretty_name,
	 file_size, owner_id,
	 parent_id)
	values
	 (:new_node, :new_filename,
	 'f', 'FileSystem uploadedFile',
	 :new_filesize, :user_id,
	 :filesystem_node)"
    }
}

db_release_unused_handles

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

ad_returnredirect index?filesystem_node=$filesystem_node

