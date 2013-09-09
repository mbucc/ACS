# /homepage/publish-2.tcl

ad_page_contract {
    Insert the customized content type according to user's submission.

    @param filesystem_node The top directory displayed.
    @param new_type_id The next type_id to insert into the database.
    @param content_type The user typed type of the published content.
    @param very_short_name The user typed short name of the published content.
    @param full_name The user typed full name of the published content.
    @param sub_section The user typed name of the sub section of the published content.

    @creation-date Jan 14 18:48:26 EST 2000
    @author mobin@mit.edu
    @cvs-id publish-2.tcl,v 3.2.2.4 2000/07/21 06:51:53 ryanlee Exp

} {
    filesystem_node:notnull,naturalnum
    content_type:notnull
    very_short_name:notnull
    full_name:notnull
    new_type_id:notnull,naturalnum
    sub_section:notnull
}

# --------------------------- initialErrorCheck codeBlock ----

#  if { ![exists_and_not_null very_short_name] } {
#      ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=Unable to create the new folder requested by the content management system.<br>It did not provide a name for it beause you did not provide 'very short name' for the content.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

#  if { ![exists_and_not_null content_type] } {
#      ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new cotent type you requested.<br>You did not provide a name for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

#  if { ![exists_and_not_null sub_section] } {
#      ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new cotent type you requested.<br>You did not provide a logical sub-class for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

#  if { ![exists_and_not_null full_name] } {
#      ad_returnredirect "dialog-class.tcl?title=Content Management&text=Unable to create the new cotent you requested.<br>You did not provide a full name for it.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
#      return
#  }

if {[regexp {.*/.*} $very_short_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested folder.<br>Attempted to access some other directory.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

if {[regexp {.*\.\..*} $very_short_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested folder.<br>Tried to access parent directory.&btn1=Okay&btn1target=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
}

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

# This query will return the quota of the user

set user_type [ad_parameter [ad_decode $admin_p \
                         0 NormalUserMaxQuota \
                         1 PrivelegedUserMaxQuota \
                         NormalUserMaxQuota] users]

set directory_space_requirement [ad_parameter DirectorySpaceRequirement users]

set sql {
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
        where filename=:very_short_name
        and parent_id=:filesystem_node) as dir_exists_p,
       hp_true_filename(:filesystem_node) as dir_dir
from dual
}

db_1row misc_info $sql

if {$quota_left < $directory_space_requirement} {
    ad_returnredirect "dialog-class.tcl?title=User Quota Management&text=Unable to create the new folder requested by the content management system.<br>You have run out of quota space.&btn1=Okay&btntarget=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return

    #    ad_return_error "Unable to Create Folder" "Sorry, you do not have enough quota spa
    #    ce available to create a new folder. A folder requires $directory_space_requirement 
    #    bytes."
    #     return
}

if {$dir_exists_p != 0} {
    ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=Unable to create the new folder requested by the content management system.<br>A folder with that name already exists.&btn1=Okay&btntarget=index.tcl&btn1keyvalpairs=filesystem_node $filesystem_node"
    return
    
    #    ad_return_error "Unable to Create Folder" "Sorry, the folder name you requested already exists."
    #    return
}

set access_denied_p [db_string access_denied_p {
    select hp_access_denied_p(:filesystem_node,:user_id) from dual
}]

set next_file_id [db_string next_file_id {
    select users_file_id_seq.nextval from dual
}]

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

    db_transaction {
	
	db_dml content_type_insert {
	    insert into users_content_types
	    (type_id,
	    type_name,
	    sub_type_name,
	    owner_id)
	    values
	    (:new_type_id,
	    :content_type,
	    :sub_section,
	    :user_id)
	}
	
	db_dml users_file_insert {
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
	    (:next_file_id, 
	    :very_short_name, 
	    't', 
	    :full_name,
	    0, 
	    :user_id, 
	    :filesystem_node,
	    't',
	    :new_type_id)
	}
    
    }

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
    
    db_dml introductory_text_insert {
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
	:user_id, 
	:next_file_id,
	't',
	'f')
    }
    
}

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect index.tcl?filesystem_node=$filesystem_node
