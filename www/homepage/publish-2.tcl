# $Id: publish-2.tcl,v 3.0.4.1 2000/04/28 15:11:03 carsten Exp $
# File:     /homepage/mkdir-2.tcl
# Date:     Fri Jan 14 18:48:26 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create a folder

set_the_usual_form_variables
# filesystem_node, content_type, very_short_name, full_name, new_type_id, sub_section

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

# Recover if having the urge to elbow out dialog-class
#if { ![info exists very_short_name] || [empty_string_p $very_short_name] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a name for the folder."
#}

if { ![info exists filesystem_node] || [empty_string_p $filesystem_node] } {
    ad_return_error "FileSystem Node Information Missing"
}

if { ![info exists new_type_id] || [empty_string_p $new_type_id] } {
    ad_return_error "new_type_id information missing"
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

if { ![info exists very_short_name] || [empty_string_p $very_short_name] } {
    ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=Unable to create the new folder requested by the content management system.<br>It did not provide a name for it beause you did not provide 'very short name' for the content.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if { ![info exists content_type] || [empty_string_p $content_type] } {
    ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new cotent type you requested.<br>You did not provide a name for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if { ![info exists sub_section] || [empty_string_p $sub_section] } {
    ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new cotent type you requested.<br>You did not provide a logical sub-class for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if { ![info exists full_name] || [empty_string_p $full_name] } {
    ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new cotent you requested.<br>You did not provide a full name for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*/.*} $very_short_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested folder.<br>Attempted to access some other directory.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*\.\..*} $very_short_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested folder.<br>Tried to access parent directory.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
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
select ((decode((select count(*) from
                users_special_quotas
                where user_id=$user_id),
                0, [ad_parameter [ad_decode $admin_p \
                         0 NormalUserMaxQuota \
                         1 PrivelegedUserMaxQuota \
                         NormalUserMaxQuota] users],
                (select max_quota from
                 users_special_quotas
                 where user_id=$user_id))) * power(2,20)) -
      ((select count(*) * [ad_parameter DirectorySpaceRequirement users]
        from users_files
        where directory_p='t'
        and owner_id=$user_id) +
       (select nvl(sum(file_size),0)
        from users_files
        where directory_p='f'
        and owner_id=$user_id)) as quota_left,
       (select count(*) from users_files
        where filename='$very_short_name'
        and parent_id=$filesystem_node) as dir_exists_p,
       hp_true_filename($filesystem_node) as dir_dir
from dual
"

# Extract results from the query
set selection [ns_db 1row $db $sql]

# This will  assign the  variables their appropriate values 
# based on the query.
set_variables_after_query

if {$quota_left < [ad_parameter DirectorySpaceRequirement users]} {
    ad_returnredirect "dialog-class.tcl?title=User Quota Management&text=Unable to create the new folder requested by the content management system.<br>You have run out of quota space.&btn1=Okay&btntarget=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return

    #ad_return_error "Unable to Create Folder" "Sorry, you do not have enough quota spa
#ce available to create a new folder. A folder requires [util_commify_number [ad_parame
#ter DirectorySpaceRequirement users]] bytes."
    #return
}

if {$dir_exists_p != 0} {
    ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=Unable to create the new folder requested by the content management system.<br>A folder with that name already exists.&btn1=Okay&btntarget=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return

#    ad_return_error "Unable to Create Folder" "Sorry, the folder name you requested already exists."
#    return
}

set access_denied_p [database_to_tcl_string $db "
select hp_access_denied_p($filesystem_node,$user_id) from dual"]

set next_file_id [database_to_tcl_string $db "
select users_file_id_seq.nextval from dual"]


# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Create Folder" "Unauthorized Access to the FileSystem"
    return
}

set dir_full_name "[ad_parameter ContentRoot users]$dir_dir/$very_short_name"

if [catch {ns_mkdir "$dir_full_name"} errmsg] {
    # directory already exists    
    append exception_text "
    <li>directory $dir_full_name could not be created."
    ad_return_complaint 1 $exception_text
    return
} else {
    ns_chmod "$dir_full_name" 0777

    ns_db dml $db "begin transaction"

    ns_db dml $db "
    insert into users_content_types
    (type_id,
    type_name,
    sub_type_name,
    owner_id)
    values
    ($new_type_id,
    '$QQcontent_type',
    '$QQsub_section',
    $user_id)
    "
    
    set dml_sql "
    insert into users_files
    (file_id, 
    filename, 
    directory_p, 
    file_pretty_name, 
    file_size, 
    owner_id, 
    parent_id,
    managed_p,
    content_type)
    values
    ($next_file_id, 
    '$QQvery_short_name', 
    't', 
    '$QQfull_name',
    0, 
    $user_id, 
    $filesystem_node,
    't',
    $new_type_id)"
    
    ns_db dml $db $dml_sql

    ns_db dml $db "end transaction"

}


# Create a file for introductory text

if [catch {set filehandle1 [open "$dir_full_name/Introductory Text" w]} errmsg] {
    # directory already exists    
    append exception_text "
    <li>file Introductory Text could not be created."
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
    managed_p,
    modifyable_p)
    values
    (users_file_id_seq.nextval, 
    'Introductory Text', 
    'f', 
    'Introductory Text',
    0, 
    $user_id, 
    $next_file_id,
    't',
    'f')"
    
    ns_db dml $db $dml_sql
}



# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node
