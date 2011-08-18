# /file-storage/upload-new-2.tcl
# 
# by aure@arsdigita.com, July 1999
#
# insert both a file and a version into the database
#
#
# ADDED 8/20: the ability to upload a url. We take either
# a url or a file, but not both. We look for an URL first.
#
# modified by randyg@arsdigita.com, January 2000 
# to use the general permissions system
#
# files, urls and folders all have at least one record in fs_vesion so that the
# permissions will work properly.  In addition, this leaves itself open to the
# options of placing permissions on the folders
# 
# $Id: upload-new-2.tcl,v 3.5.2.3 2000/04/28 15:10:28 carsten Exp $

ad_page_variables {
    {file_id}
    {file_title}
    {group_id ""}
    {parent_id}
    {public_p "f"}
    {return_url}
    {upload_file}
    {url}
    {version_id}
    {version_description "" qq}
}


set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

# check the user input first

set exception_text ""
set exception_count 0

if [empty_string_p $file_title] {
    append exception_text "<li>You must give a title\n"
    incr exception_count
}

if {[empty_string_p $url] && (![info exists upload_file] || [empty_string_p $upload_file])} {
    append exception_text "<li>You need to upload a file or enter a URL\n"
    incr exception_count
}

if {[info exists url] && ![empty_string_p $url] && [info exists upload_file] && ![empty_string_p $upload_file]} {
    append exception_text "<li>You can not both add a url and upload a file"
    incr exception_count
}

if {$public_p == "t" && ![ad_parameter PublicDocumentTreeP fs]} {
    append exception_text "<li> [ad_system_name] does not support a public directory tree. \n"
    incr exception_count
} 

if ![empty_string_p $group_id] {
    if { ![ad_user_group_member $db $group_id $user_id] } {
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


if {[string compare $public_p t] == 0} {
    set public_read_p t
    set public_write_p t
    set public_comment_p t
} else {
    set public_read_p f
    set public_write_p f
    set public_comment_p f
}



if [empty_string_p $url] {

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

    set file_insert "
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
        $file_id, 
        '[DoubleApos $file_title]', 
        $user_id, 
        [ns_dbquotevalue $parent_id],
        0,
        0, 
        '[DoubleApos $group_id]', 
        '$public_p')"

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
        $version_id, 
        $file_id, 
        '$QQversion_description', 
        sysdate, 
        $user_id, 
        '[DoubleApos $client_filename]', 
        '$guessed_file_type', 
        '$file_extension', 
        $n_bytes, 
        empty_blob())
    returning version_content into :1" 

    ns_db dml $db "begin transaction"

    if {[catch { ns_db dml $db $file_insert } errmsg] } {

        # insert failed; let's see if it was because of duplicate submission

        if { [database_to_tcl_string $db "select count(*) from fs_files where file_id = $file_id"] == 0 } {

	    ns_log Error "/file-storage/create-folder-2.tcl choked:  $errmsg"

	    ad_return_error "Insert Failed" "The Database did not like what 
	        you typed.  This is probably a bug in our code.  Here's what 
	        the database said:
	        <blockquote>
	        <pre>$errmsg</pre>
	        </blockquote>"

            return
        }

        ns_db dml $db "abort transaction"

        # we don't bother to handle the cases where there is a dupe 
        # submission because the user should be thanked or 
        # redirected anyway

	# return/redirect Netscape users, but give MSIE users a redirecting page

	if [regexp "MSIE" [ns_set get [ns_conn headers] User-Agent]] {
	    ns_return 200 text/html "<meta http-equiv=\"refresh\" content=\"0; URL=$return_url\">"
	} else {
	    ad_returnredirect $return_url
	}
    }

    # don't need double-click protection here since we already did 
    # that for previous statement

    ns_ora blob_dml_file $db $version_insert $tmp_filename

    # now that the version has been inserted, let's set up the permissions

    if { [string compare $public_p t] == 0 } {
        ns_ora exec_plsql $db "begin
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('read', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('write', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('comment', $version_id, 'FS_VERSIONS');
end;"
    }

    ns_ora exec_plsql $db "begin
 :1 := ad_general_permissions.grant_permission_to_user
        ($user_id, 'read', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($user_id, 'write', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($user_id, 'comment', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($user_id, 'administer', $version_id, 'FS_VERSIONS');
end;"

    fs_order_files $db

    ns_db dml $db "end transaction"

    set return_url "/file-storage/$return_url"
    set object_name "$file_title"
    set on_what_id $version_id
    set on_which_table FS_VERSIONS
    set return_url "/gp/administer-permissions?[export_url_vars return_url object_name on_what_id on_which_table]"

    if [regexp "MSIE" [ns_set get [ns_conn headers] User-Agent]] {
	ReturnHeaders
	ns_write "<meta http-equiv=\"refresh\" content=\"0; URL=$return_url\">"
    } else {
	ad_returnredirect $return_url
    }

} else {

    set file_insert "
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
        $file_id, 
        '[DoubleApos $file_title]',
        $user_id, 
        [ns_dbquotevalue $parent_id],
        0,
        0, 
        '[DoubleApos $group_id]', 
        '$public_p')"

    set version_insert "
    insert into fs_versions
    (version_id, file_id, version_description, creation_date, author_id, url)
    values
    ($version_id, $file_id, '$QQversion_description', sysdate, $user_id, '$QQurl')"


    if {[catch { ns_db dml $db "begin transaction"
	         ns_db dml $db $file_insert 
                 ns_db dml $db $version_insert} errmsg] } {
        # insert failed; let's see if it was because of duplicate submission
        if { [database_to_tcl_string $db "select count(*) from fs_files where file_id = $file_id"] == 0 } {
	    ns_log Error "/file-storage/create-folder-2.tcl choked:  $errmsg"
	    ad_return_error "Insert Failed" "The Database did not like what you 
	        typed.  This is probably a bug in our code.  Here's what the 
	        database said:
	        <blockquote>
	        <pre>$errmsg</pre>
	        </blockquote>"

            ns_db dml $db "abort transaction"
            return
        }
    }

    # now that the version has been inserted, let's set up the permissions
    if { [string compare $public_p t] == 0 } {
        ns_ora exec_plsql $db "begin
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('read', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('write', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('comment', $version_id, 'FS_VERSIONS');
end;"
    }

        ns_ora exec_plsql $db "begin
 :1 := ad_general_permissions.grant_permission_to_user
        ($user_id, 'read', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($user_id, 'write', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
         ($user_id, 'comment', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($user_id, 'administer', $version_id, 'FS_VERSIONS');
end;"

    fs_order_files $db

    ns_db dml $db "end transaction"

    set return_url "/file-storage/$return_url"
    set object_name "$file_title"
    set on_what_id $version_id
    set on_which_table FS_VERSIONS
    set return_url "/gp/administer-permissions?[export_url_vars return_url object_name on_what_id on_which_table]"

    if [regexp "MSIE" [ns_set get [ns_conn headers] User-Agent]] {
	ns_return 200 text/html "<meta http-equiv=\"refresh\" content=\"0; URL=$return_url\">"
    } else {
	ad_returnredirect $return_url
    }
}

