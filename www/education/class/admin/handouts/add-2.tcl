# 
# /www/education/class/admin/handouts/add-.tcl
#
# this is almost identical to the page /education/util/upload-new.tcl
# there are a few changes that allow an an insert into edu_handouts to
# occur.  There is an extra insert at the bottom of the page and then
# it takes (and checks) some extra arguments in the ad_page_variables
#
# revised by randyg@arsdigita.com, aileen@mit.edu, January 2000
#


ad_page_variables {
    {upload_file ""}
    {url ""}
    file_title
    file_id
    version_id
    parent_id
    type
    handout_id
    {ColValue.distribution%5fdate.year ""}
    {ColValue.distribution%5fdate.day ""}
    {ColValue.distribution%5fdate.month ""}
    {write_permission ta}
    {read_permission ""}
    {version_description ""}
    {return_url ""}
}

# either the upload file or the url must be not null and the other one must be null


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


# check the user input first

set exception_text ""
set exception_count 0


if {[empty_string_p $url] && (![info exists upload_file] || [empty_string_p $upload_file])} {
    append exception_text "<li>You need to upload a file or enter a URL\n"
    incr exception_count
}

if {![empty_string_p $url] && ![empty_string_p $upload_file]} {
    append exception_text "<li>You can not both add a url and upload a file"
    incr exception_count
}


if {[empty_string_p $file_title]} {
    incr exception_count
    append exception_text "<li>You must include a title for this file."
}


# put together due_date, and do error checking

set form [ns_getform]

# ns_dbformvalue $form due_date date due_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.due%5fdate.day and stick the new value into the $form
# ns_set.

set "ColValue.distribution%5fdate.day" [string trimleft [set ColValue.distribution%5fdate.day] "0"]
ns_set update $form "ColValue.distribution%5fdate.day" [set ColValue.distribution%5fdate.day]

if [catch  { ns_dbformvalue $form distribution_date date distribution_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.distribution%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} 


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}


if {[database_to_tcl_string $db "select count(version_id) from fs_versions where version_id = $version_id"] > 0 || [database_to_tcl_string $db "select count(file_id) from fs_files where file_id = $file_id"] > 0} {
    # this was a double click
    ad_returnredirect $return_url
    return
}


# set the variables that are the same for all

set public_p f


if [empty_string_p $url] {

    # get the file from the user.
    # number_of_bytes is the upper-limit
    set max_n_bytes [ad_parameter MaxNumberOfBytes fs]
    
    set tmp_filename [ns_queryget upload_file.tmpfile]
    set version_content [read [open $tmp_filename] $max_n_bytes]
    
    set file_extension [string tolower [file extension $upload_file]]
    # remove the first . from the file extension
    regsub "\." $file_extension "" file_extension
    
    set guessed_file_type [ns_guesstype $upload_file]
    
    set n_bytes [file size $tmp_filename]
    
    # strip off the C:\directories... crud and just get the file name
    if ![regexp {([^//\\]+)$} $upload_file match client_filename] {
	# couldn't find a match
	set client_filename $upload_file
    }
    
    set file_insert "insert into fs_files
    (file_id, file_title, owner_id, parent_id, sort_key, depth, group_id, public_p)
    values
    ($file_id, [ns_dbquotevalue $file_title], $user_id, [ns_dbquotevalue $parent_id],0,0, $group_id, '$public_p')
    "
    
    set version_insert "insert into fs_versions
    (version_id, file_id, version_description, creation_date, author_id, client_file_name, file_type, file_extension, n_bytes, version_content)
    values
    ($version_id, $file_id, [ns_dbquotevalue $version_description], sysdate, $user_id, '[DoubleApos $client_filename]', '$guessed_file_type', '$file_extension', $n_bytes, empty_blob())
    returning version_content into :1" 
    
    ns_db dml $db "begin transaction"
    if {[catch { ns_db dml $db $file_insert } errmsg] } {
         # insert failed; let's see if it was because of duplicate submission
         if { [database_to_tcl_string $db "select count(*) from fs_files where file_id = $file_id"] == 0 } {
	     ns_log Error "[edu_url]group/admin/upload-new.tcl choked:  $errmsg"
	     ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
	     <blockquote>
	     <pre>
	     $errmsg
	     </pre>
	     </blockquote>
	     "
             return
         }
         ns_db dml $db "abort transaction"
	 # we don't bother to handle the cases where there is a dupe 
	 # submission because the user should be thanked or 
	 # redirected anyway
	 ad_returnredirect $return_url
    }
     
    # don't need double-click protection here since we already did 
    # that for previous statement
    ns_ora blob_dml_file $db $version_insert $tmp_filename
    
} else {

    set file_insert "insert into fs_files
    (file_id, file_title, owner_id, parent_id, sort_key, depth, group_id, public_p)
    values
    ($file_id, [ns_dbquotevalue $file_title], $user_id, [ns_dbquotevalue $parent_id],0,0,$group_id, '$public_p')
    "
    
    set version_insert "insert into fs_versions
    (version_id, file_id, version_description, creation_date, author_id, url)
    values
    ($version_id, $file_id, [ns_dbquotevalue $version_description], sysdate, $user_id, [ns_dbquotevalue $url])"
    
    
    if {[catch { ns_db dml $db "begin transaction"
 	         ns_db dml $db $file_insert 
                  ns_db dml $db $version_insert} errmsg] } {
         # insert failed; let's see if it was because of duplicate submission
         if { [database_to_tcl_string $db "select count(*) from fs_files where file_id = $file_id"] == 0 } {
 	    ns_log Error "[edu_url]group/admin/upload-new.tcl choked:  $errmsg"
 	    ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
	    <blockquote>
	    <pre>
	    $errmsg
	    </pre>
	    </blockquote>
	    "
            ns_db dml $db "abort transaction"
            return
        }
    }
}
 

#
# the permissions makes the assumption that the roles are a hierarchical 
# by the priority column
#

# lets first give the uploading user permissions on the document

ns_ora exec_plsql $db "begin
 :1 := ad_general_permissions.grant_permission_to_user ( $user_id, 'read', $version_id, 'FS_VERSIONS' );
 :1 := ad_general_permissions.grant_permission_to_user ( $user_id, 'write', $version_id, 'FS_VERSIONS' );
 :1 := ad_general_permissions.grant_permission_to_user ( $user_id, 'comment', $version_id, 'FS_VERSIONS' );
 :1 := ad_general_permissions.grant_permission_to_user ( $user_id, 'administer', $version_id, 'FS_VERSIONS' );
end;"



# lets do the write permissions next

if {[empty_string_p $write_permission]} {
    # insert write permission for the public
   ns_ora exec_plsql $db "begin 
 :1 := ad_general_permissions.grant_permission_to_all_users ( 'write', $version_id, 'FS_VERSIONS' ); 
 :1 := ad_general_permissions.grant_permission_to_all_users ( 'read', $version_id, 'FS_VERSIONS' );
 :1 := ad_general_permissions.grant_permission_to_all_users ( 'comment', $version_id, 'FS_VERSIONS' ); end;"

    set write_permission_priority -1
} else {
    # a specific role has write permission.  In this case, we want to 
    # give write permisison to every group with a priority greater than
    # the given role
    set write_permission_priority [database_to_tcl_string $db "select priority from edu_role_pretty_role_map where group_id = $group_id and lower(role) = lower('$write_permission')"]

    set role_list [database_to_tcl_list $db "select role from edu_role_pretty_role_map where group_id = $group_id and priority <= $write_permission_priority"]

    # now, lets go through the role_list and add write permissions
    # but, if you want write permissions, you should also have read and comment permission
    foreach role $role_list {
	ns_ora exec_plsql $db "begin 
        :1 := ad_general_permissions.grant_permission_to_role ( $group_id, '$role', 'write', $version_id, 'FS_VERSIONS' ); 
        :1 := ad_general_permissions.grant_permission_to_role ( $group_id, '$role', 'read', $version_id, 'FS_VERSIONS' ); 
        :1 := ad_general_permissions.grant_permission_to_role ( $group_id, '$role', 'comment', $version_id, 'FS_VERSIONS' ); end;"
    }
}


# now, we do read permissions pretty much the same way.  The general
# permissions functions assume that if you have write, you automatically
# have read so if the role has write, we are not going to add read again

if {[empty_string_p $read_permission]} {
    # insert write permission for the public
    if {$write_permission_priority > -1} {
	# the public cannot write
	ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_all_users ( 'read', $version_id, 'FS_VERSIONS' );
                                     :1 := ad_general_permissions.grant_permission_to_all_users ( 'comment', $version_id, 'FS_VERSIONS' ); end;"  
    }
} else {
    # a specific role has write permission.  In this case, we want to 
    # give write permisison to every group with a priority greater than
    # the given role
    set read_permission_priority [database_to_tcl_string $db "select priority from edu_role_pretty_role_map where group_id = $group_id and lower(role) = lower('$read_permission')"]

    if {$read_permission_priority > $write_permission_priority} {
	# there are users that should have read and do not already have write
	set role_list [database_to_tcl_list $db "select role from edu_role_pretty_role_map where group_id = $group_id and priority > $write_permission_priority and priority <= $read_permission_priority"]

	# now, lets go through the role_list
	foreach role $role_list {
	    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_role ( $group_id, '$role', 'read', $version_id, 'FS_VERSIONS' );
                                         :1 := ad_general_permissions.grant_permission_to_role ( $group_id, '$role', 'comment', $version_id, 'FS_VERSIONS' ); end;"
	}
    }
}


fs_order_files $db $user_id $group_id $public_p


# the last thing that we want to do is the insert into edu_handouts

ns_db dml $db "insert into edu_handouts (
	handout_id,
	class_id,
	handout_name,
	file_id,
	handout_type,
	distribution_date)
    values (
        $handout_id,
        $group_id,
        '$QQfile_title',
        $file_id,
        '$type',
        '$distribution_date')"


ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect $return_url











