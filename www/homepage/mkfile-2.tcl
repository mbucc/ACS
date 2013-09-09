# File:     /homepage/mkfile-2.tcl

ad_page_contract {
    Page to create a new file

    @param filesystem_node System variable to get us back to the start
    @param new_name New file name
    @param new_desc New file description

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Wed Jan 19 21:36:48 EST 2000
    @cvs-id mkfile-2.tcl,v 3.2.2.7 2000/07/21 04:00:43 ron Exp
} {
    filesystem_node:notnull,naturalnum
    new_name:notnull,trim
    new_desc:notnull,trim
}

# --------------------------- initialErrorCheck codeBlock ----

# exception_text used later
# set exception_count 0
set exception_text ""

# Deactivated code. Due to the new dialog-class
#if { ![info exists new_name] || [empty_string_p $new_name] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a filename"
#}

#  if { ![info exists new_name] || [empty_string_p $new_name] } {
#      ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to create the new file you requested.<br>You did not provide a name for it.&btn1=Okay&btntarget=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

#  if { ![info exists new_desc] || [empty_string_p $new_desc] } {
#      ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to create the new file you requested.<br>You did not provide a description for it.&btn1=Okay&btntarget=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

if {[regexp {.*\.\..*} $new_name match]} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the requested file.<br>Attempted to access parent filesystem node.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*/.*} $new_name match]} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the requested file.<br>Attempted to access some other folder.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
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

set dir_dir [db_string select_fs_dir_name "
select hp_true_filename(:filesystem_node)
from dual"]

set new_fullname "[ad_parameter ContentRoot users]$dir_dir/$new_name"

if {[file exists $new_fullname]} {
    ad_returnredirect "dialog-class?title=Filesystem Management&text=Sorry, a file with that name already exists.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

set access_denied_p [db_string select_access_denied_p "
select hp_access_denied_p(:filesystem_node,:user_id) from dual"]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Create File" "Unauthorized Access to the FileSystem"
    return
}

if [catch {set filehandle1 [open "$new_fullname" w]} errmsg] {
    # directory already exists    
    append exception_text "
    <li>file $new_fullname could not be created."
    ad_return_complaint 1 $exception_text
    return
} else {
    close $filehandle1
    set dml_sql "
    insert into users_files
    (file_id, 
    filename, 
    directory_p, 
    file_pretty_name, 
    file_size, 
    owner_id, 
    parent_id)
    values
    (users_file_id_seq.nextval, 
    :new_name, 
    'f', 
    :new_desc,
    0, 
    :user_id, 
    :filesystem_node)"
    
    db_dml create_new_file $dml_sql
}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index?filesystem_node=$filesystem_node
