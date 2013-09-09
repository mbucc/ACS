ad_page_contract {
    insert both a file and a version into the database

    ADDED 8/20: the ability to upload a url. We take either
    a url or a file, but not both. We look for an URL first.

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id upload-new-2.tcl,v 3.11.2.10 2001/01/10 18:47:06 khy Exp

    modified by randyg@arsdigita.com, January 2000 
    to use the general permissions system
    
    files, urls and folders all have at least one record in fs_vesion so that the
    permissions will work properly.  In addition, this leaves itself open to the
    options of placing permissions on the folders
} {
    file_id:integer,notnull,verify
    file_title:trim,notnull
    {group_id ""}
    parent_id:integer
    {public_p "f"}
    {return_url}
    {upload_file ""}
    {url ""}
    {version_id:integer,verify}
    {version_description:string_length(max|500) ""}
} 

set user_id [ad_maybe_redirect_for_registration]

# check the user input first

set exception_text ""
set exception_count 0

# check if the url starts with http:// or https:// or ftp://
if { ![empty_string_p $url] && ![regexp -nocase {^(http://|https://|ftp://)} $url] } {
    append exception_text "<li>The URL must start with http://, https:// or ftp://\n"
    incr exception_count
}


if {[empty_string_p $url] && (![info exists upload_file] || [empty_string_p $upload_file])} {
    append exception_text "<li>You need to upload a file or enter a URL\n"
    incr exception_count
}

if {![empty_string_p $url] && ![empty_string_p $upload_file]} {
    append exception_text "<li>You can not both add a url and upload a file"
    incr exception_count
}

if {$public_p == "t" && ![ad_parameter PublicDocumentTreeP fs]} {
    append exception_text "<li> [ad_system_name] does not support a public directory tree. \n"
    incr exception_count
} 

if ![empty_string_p $group_id] {
    if { ![ad_user_group_member $group_id $user_id] } {
	append exception_text "<li>You are not a member of this group.\n"
	incr exception_count
    }
} else {
    set group_id ""
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

if { [empty_string_p $url] } {
    # We are processing a file, not a URL.
    # get the file from the user.
    # number_of_bytes is the upper-limit
    set max_n_bytes [ad_parameter MaxNumberOfBytes fs]
    
    set tmp_filename [ns_queryget upload_file.tmpfile]

    if { ![empty_string_p $max_n_bytes] && ([file size $tmp_filename] > $max_n_bytes) } {
	ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
	return 0
    }

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

    set version_insert "
    insert into fs_versions (
        version_id, 
        file_id, 
        version_description, 
        creation_date, 
        author_id, 
        client_file_name, 
        file_type, 
        file_extension, 
        n_bytes, 
        version_content)
    values (
        :version_id, 
        :file_id, 
        :version_description, 
        sysdate, 
        :user_id, 
        :client_filename,
        :guessed_file_type, 
        :file_extension, 
        :n_bytes, 
        empty_blob())
    returning version_content into :1" 
} else {
    # We are processing a url, not a file.
    set version_insert "
	insert into fs_versions
	(version_id, file_id, version_description, creation_date, author_id, url)
	values
	(:version_id, :file_id, :version_description, sysdate, :user_id, :url)"
}

db_transaction {
    db_dml file_insert {
	insert into fs_files (
			      file_id, 
			      file_title, 
			      owner_id, 
			      parent_id, 
			      sort_key, 
			      depth, 
			      group_id, 
			      public_p)
	values (
		:file_id, 
		:file_title,
		:user_id, 
		:parent_id,
		0,
		0, 
		:group_id, 
		:public_p)
    }
	   
    if { [empty_string_p $url] } {
	db_dml version_insert $version_insert -blob_files [list $tmp_filename]
    } else {
	db_dml version_insert $version_insert
    }
    # now that the version has been inserted, let's set up the permissions

    if { [string compare $public_p t] == 0 } {
	db_exec_plsql fs_public_permission_insert {
	    begin
	    :1 := ad_general_permissions.grant_permission_to_all_users
	    ('read', :version_id, 'FS_VERSIONS');
	    :1 := ad_general_permissions.grant_permission_to_all_users
	    ('write', :version_id, 'FS_VERSIONS');
	    :1 := ad_general_permissions.grant_permission_to_all_users
	    ('comment', :version_id, 'FS_VERSIONS');
	    end;
	} 
    }
    
    db_exec_plsql fs_user_permission_insert {
	begin
	:1 := ad_general_permissions.grant_permission_to_user
	(:user_id, 'read', :version_id, 'FS_VERSIONS');
	:1 := ad_general_permissions.grant_permission_to_user
	(:user_id, 'write', :version_id, 'FS_VERSIONS');
	:1 := ad_general_permissions.grant_permission_to_user
	(:user_id, 'comment', :version_id, 'FS_VERSIONS');
	:1 := ad_general_permissions.grant_permission_to_user
	(:user_id, 'administer', :version_id, 'FS_VERSIONS');
	end;
    }

} on_error {
    # insert failed; let's see if it was because of duplicate submission

    if { [db_string num_duplicates "select count(*) from fs_files where file_id = $file_id"] == 0 } {
	
	ns_log Error "/file-storage/create-folder-2.tcl choked:  $errmsg"
	
	ad_return_error "Insert Failed" "The Database did not like what 
	        you typed.  This is probably a bug in our code.  Here's what 
	        the database said:
	        <blockquote>
	        <pre>$errmsg</pre>
	        </blockquote>"
	ad_script_abort
    } else {
	# we don't bother to handle the cases where there is a dupe 
	# submission because the user should be thanked or 
	# redirected anyway

	# return/redirect Netscape users, but give MSIE users a redirecting page
    
	if [regexp "MSIE" [ns_set get [ns_conn headers] User-Agent]] {
	    doc_return  200 text/html "<meta http-equiv=\"refresh\" content=\"0; URL=$return_url\">"
	} else {
	    ad_returnredirect $return_url
	}
	ad_script_abort
    }
}

fs_order_files
	
# Code common to inserting a file and a url.
set return_url "/file-storage/$return_url"
set object_name "$file_title"
set on_what_id $version_id
set on_which_table FS_VERSIONS
set return_url "/gp/administer-permissions?[export_url_vars return_url object_name on_what_id on_which_table]"

# this code is preserved in case not all compilations of AOLserver 3.0
# have fixed the AOLserver 2.3.3 issue with passing parameters on
# redirect if you were using IE

if [regexp "MSIE" [ns_set get [ns_conn headers] User-Agent]] {
    doc_return  200 text/html "<meta http-equiv=\"refresh\" content=\"0; URL=$return_url\">"
} else {
    ad_returnredirect $return_url
}

# not sure why this code is still preserved for posterity 
# could have been when Oracle driver was not fully ready

#  db_with_handle db {
# 	if { [string compare $public_p t] == 0 } {
# 	    ns_ora exec_plsql $db "begin
# 		:1 := ad_general_permissions.grant_permission_to_all_users
# 		('read', $version_id, 'FS_VERSIONS');
# 		:1 := ad_general_permissions.grant_permission_to_all_users
# 		('write', $version_id, 'FS_VERSIONS');
# 		:1 := ad_general_permissions.grant_permission_to_all_users
# 		('comment', $version_id, 'FS_VERSIONS');
# 		end;"
# 	}
#   	ns_ora exec_plsql $db "begin
# 	    :1 := ad_general_permissions.grant_permission_to_user
# 	    ($user_id, 'read', $version_id, 'FS_VERSIONS');
# 	    :1 := ad_general_permissions.grant_permission_to_user
# 	    ($user_id, 'write', $version_id, 'FS_VERSIONS');
# 	    :1 := ad_general_permissions.grant_permission_to_user
# 	    ($user_id, 'comment', $version_id, 'FS_VERSIONS');
# 	    :1 := ad_general_permissions.grant_permission_to_user
# 	    ($user_id, 'administer', $version_id, 'FS_VERSIONS');
# 	    end;"
#     }