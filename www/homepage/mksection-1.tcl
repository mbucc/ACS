# $Id: mksection-1.tcl,v 3.1.4.1 2000/04/28 15:11:02 carsten Exp $
# File:     /homepage/mkfile-2.tcl
# Date:     Wed Jan 19 21:36:48 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create a new file

set_the_usual_form_variables
# filesystem_node, section_title, section_desc, section_type

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

# Deactivated code. Due to the new dialog-class
#if { ![info exists section_title] || [empty_string_p $section_title] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a filename"
#}

if { ![info exists filesystem_node] || [empty_string_p $filesystem_node] } {
    ad_return_error "FileSystem Node Information Missing"
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

if { ![info exists section_title] || [empty_string_p $section_title] } {
    ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new section you requested.<br>You did not provide a name for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if { ![info exists section_desc] || [empty_string_p $section_desc] } {
    ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new section you requested.<br>You did not provide a title for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*\.\..*} $section_title match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested file.<br>Attempted to access parent filesystem node.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*/.*} $section_title match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested file.<br>Attempted to access some other folder.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
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

set dir_dir [database_to_tcl_string $db "
select hp_true_filename($filesystem_node)
from dual"]

set new_fullname "[ad_parameter ContentRoot users]$dir_dir/$section_title"

if {[file exists $new_fullname]} {
    ad_returnredirect "dialog-class.tcl?title=Content Management&text=Sorry, a $section_type with that name already exists.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

set access_denied_p [database_to_tcl_string $db "
select hp_access_denied_p($filesystem_node,$user_id) from dual"]

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
    parent_id,
    managed_p)
    values
    (users_file_id_seq.nextval, 
    '$QQsection_title', 
    'f', 
    '$QQsection_desc',
    0, 
    $user_id, 
    $filesystem_node,
    't')"
    
    ns_db dml $db $dml_sql
}

# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node







