# File:     /homepage/mksection-1.tcl

ad_page_contract {
    Page to create a new file.

    @param filesystem_node The ID of the node in the filesystem
    @param section_title The new section title
    @param section_desc The new section description
    @param section_type The new type of section

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Wed Jan 19 21:36:48 EST 2000
    @cvs-id mksection-1.tcl,v 3.3.2.8 2000/07/21 06:45:07 ryanlee Exp
} {
    filesystem_node:notnull,integer
    section_title:notnull,trim
    section_desc:notnull,trim
    section_type:notnull,trim
}

# --------------------------- initialErrorCheck codeBlock ----


# Lots of this is deactivated until Usman comes in to figure
# out to handle the errors
# 
# exception_text is used later on for errors as they arrive
# set exception_count 0
set exception_text ""

# Deactivated code. Due to the new dialog-class
#if { ![info exists section_title] || [empty_string_p $section_title] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a filename"
#}

#  if { ![info exists section_title] || [empty_string_p $section_title] } {
#      ad_returnredirect "dialog-class?title=Content Management&text=Unable to create the new section you requested.<br>You did not provide a name for it.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

#  if { ![info exists section_desc] || [empty_string_p $section_desc] } {
#      ad_returnredirect "dialog-class?title=Content Management&text=Unable to create the new section you requested.<br>You did not provide a title for it.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

if {[regexp {.*\.\..*} $section_title match]} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the requested file.<br>Attempted to access parent filesystem node.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*/.*} $section_title match]} {
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

set new_fullname "[ad_parameter ContentRoot users]$dir_dir/$section_title"

if {[file exists $new_fullname]} {
    ad_returnredirect "dialog-class?title=Content Management&text=Sorry, a $section_type with that name already exists.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
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
    <li>File $new_fullname could not be created."
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
    parent_id,
    managed_p)
    values
    (users_file_id_seq.nextval, 
    :section_title, 
    'f', 
    :section_desc,
    0, 
    :user_id, 
    :filesystem_node,
    't')"
    
    db_dml insert_new_sectino $dml_sql
}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index?filesystem_node=$filesystem_node

