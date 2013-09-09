# /homepage/mkdir-2.tcl

ad_page_contract {
    Create a folder according to user's submission.
    
    @param filesystem_node The top directory displayed.
    @param dir_name The user typed new directory desired name.
    @param dir_desc The user typed description.

    @creation-date Fri Jan 14 18:48:26 EST 2000
    @author mobin@mit.edu
    @cvs-id mkdir-2.tcl,v 3.2.2.5 2001/02/04 22:27:55 kevin Exp
} {
    filesystem_node:naturalnum
    dir_name:notnull
    dir_desc:notnull
}

# --------------------------- initialErrorCheck codeBlock ----

#  if { ![exists_and_not_null dir_name] } {
#      ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to create the new folder you requested.<br>You did not provide a name for it.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

#  if { ![exists_and_not_null dir_desc] } {
#      ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to create the new folder you requested.<br>You did not provide a description for it.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

if {[regexp {.*/.*} $dir_name match]} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the requested folder.<br>Attempted to access some other directory.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*\.\..*} $dir_name match]} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the requested folder.<br>Tried to access parent directory.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

# This query will return the quota of the user

set user_type [ad_parameter [ad_decode :admin_p \
                         0 NormalUserMaxQuota \
                         1 PrivelegedUserMaxQuota \
                         NormalUserMaxQuota] users]


set directory_space_requirement [ad_parameter DirectorySpaceRequirement users]

set sql "
select ((decode((select count(*) from
                users_special_quotas
                where user_id=:user_id),
                0, :user_type,
                (select max_quota from
                 users_special_quotas
                 where user_id=:user_id))) * power(2,20)) -
      ((select count(*) * :directory_space_requirement
        from users_files
        where directory_p='t'
        and owner_id=:user_id) +
       (select nvl(sum(file_size),0)
        from users_files
        where directory_p='f'
        and owner_id=:user_id)) as quota_left,
       (select count(*) from users_files
        where filename=:dir_name
        and parent_id=:filesystem_node) as dir_exists_p,
       hp_true_filename(:filesystem_node) as dir_dir
from dual
"

db_1row misc_info_get $sql

if {$quota_left < $directory_space_requirement} {
    ad_returnredirect "dialog-class?title=User Quota Management&text=Unable to create the new folder you requested.<br>You have run out of quota space.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {$dir_exists_p != 0} {
    ad_returnredirect "dialog-class?title=Filesystem Management&text=Unable to create the new folder you requested.<br>A folder with that name already exists.&btn1=Okay&btn1target=index&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

set access_denied_p [db_string access_denied_p "
select hp_access_denied_p($filesystem_node,$user_id) from dual"]

# Check to see whether the user is the owner of the filesystem node
# for which access is requested.
if {$access_denied_p} {
    # Aha! url surgery attempted!
    ad_return_error "Unable to Create Folder" "Unauthorized Access to the FileSystem"
    return
}

set dir_full_name "[ad_parameter ContentRoot users]$dir_dir/$dir_name"

if [catch {ns_mkdir "$dir_full_name"} errmsg] {
    # directory already exists    
    append exception_text "
    <li>directory $dir_full_name could not be created.  The error
was <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
    ad_return_complaint 1 $exception_text
    return
} else {
    ns_chmod "$dir_full_name" 0777
    
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
    :dir_name, 
    't', 
    :dir_desc,
    0, 
    :user_id, 
    :filesystem_node)"
    
    db_dml folder_insert $dml_sql
}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index?filesystem_node=$filesystem_node
