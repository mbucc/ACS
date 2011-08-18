# /file-storage/version-upload-2.tcl
#
# by aure@arsdigita.com July, 1999
#
# extended in January 2000 by randyg@arsdigita.com
# to accomodate general permission system
#
# $Id: version-upload-2.tcl,v 3.1.2.4 2000/04/28 15:10:29 carsten Exp $

ad_page_variables {
    {file_id}
    {group_id ""}
    {return_url}
    {upload_file}
    {version_id}
    {version_description "" qq}
}

set local_user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# check the user input first

set exception_text ""
set exception_count 0

if [empty_string_p $file_id] {
    incr exception_count
    append exception_text "<li>No file was specified"
}

set selection [ns_db 1row $db "
    select version_id as old_version_id, author_id as old_author_id
    from fs_versions_latest
    where file_id = $file_id
"]

set_variables_after_query

if {! [fs_check_write_p $db $local_user_id $old_version_id $group_id]} {
    incr exception_count
    append exception_text "<li>You can't write into this file"
}

if [empty_string_p $upload_file] {
    append exception_text "<li>You need to upload a file\n"
    incr exception_count
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# get the file from the user.
# number_of_bytes is the upper-limit
# on the size of the file we will read. 1024*1024*2= 2097142
set max_n_bytes [ad_parameter MaxNumberOfBytes fs]

set tmp_filename [ns_queryget upload_file.tmpfile]
set version_content [read [open $tmp_filename] $max_n_bytes]

if { ![empty_string_p $max_n_bytes] && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return 0
}


set file_extension [string tolower [file extension $upload_file]]
# remove the first . from the file extension
regsub "\." $file_extension "" file_extension

# Guess a mime type for this file. If it turns out to be text/plain (the
# default for anything ns_guesstype doesn't understand), retain the old
# file type on the assumption that the user has edited the type.

set guessed_file_type [ns_guesstype $upload_file]

if { $guessed_file_type == "text/plain" } {
    set guessed_file_type [database_to_tcl_string $db "select file_type from fs_versions_latest
where file_id = $file_id"]
}


set n_bytes [file size $tmp_filename]

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match client_filename] {
    # couldn't find a match
    set client_filename $upload_file
}

set version_insert "insert into fs_versions
(version_id, file_id, version_description, creation_date, author_id, client_file_name, file_type, file_extension, n_bytes, version_content)
values
($version_id, $file_id, '$QQversion_description', sysdate, $local_user_id, '[DoubleApos $client_filename]', '$guessed_file_type', '$file_extension', $n_bytes, empty_blob())
returning version_content into :1" 

    ns_db dml $db "begin transaction"
    if {[catch { ns_ora blob_dml_file $db $version_insert $tmp_filename } errmsg] } {
        # insert failed; let's see if it was because of duplicate submission
        if { [database_to_tcl_string $db "select count(*) from fs_files where file_id = $file_id"] == 0 } {
	    ns_log Error "/file-storage/create-folder-2.tcl choked:  $errmsg"
	    ad_return_error "Insert Failed" "The Database did not like what you 
	                     typed.  This is probably a bug in our code.  Here's 
	                     what the database said:
	                     <blockquote>
	                     <pre>$errmsg</pre>
	                     </blockquote>"
            return
        }

        ns_db dml $db "abort transaction"
        # we don't bother to handle the cases where there is a dupe 
        # submission because the user should be thanked or 
        # redirected anyway
        
	if [regexp "MSIE" [ns_set get [ns_conn headers] User-Agent]] {
	    ReturnHeaders
	    ns_write "<meta http-equiv=\"refresh\" content=\"0; URL=$return_url\">"
	} else {
	    ad_returnredirect $return_url
	}

    }

    ns_db dml $db  "
        update fs_versions 
        set   superseded_by_id = $version_id 
        where file_id = $file_id
        and   version_id <> $version_id"


    # now that the version has been inserted, lets set up the permissions

    # we don't need double-click protection here since we already did 
    # that for previous statement


    # Copy the previous version's permissions, except for rows regarding
    # the current user and the previous version's owner.

    ns_ora exec_plsql $db "begin
       ad_general_permissions.copy_permissions
        ($old_version_id, $version_id, 'FS_VERSIONS', 
	 $local_user_id, $old_author_id);
 :1 := ad_general_permissions.grant_permission_to_user
        ($local_user_id, 'read', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($local_user_id, 'write', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($local_user_id, 'comment', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_user
        ($local_user_id, 'administer', $version_id, 'FS_VERSIONS');
end;"

ns_db dml $db "end transaction"

set object_name [database_to_tcl_string $db "
    select file_title 
    from   fs_files 
    where  file_id = $file_id"]
set on_what_id $version_id
set on_which_table "FS_VERSIONS"

ns_db releasehandle $db

set return_url "/gp/administer-permissions?[export_url_vars return_url object_name on_what_id on_which_table]"

if [regexp "MSIE" [ns_set get [ns_conn headers] User-Agent]] {
    ReturnHeaders
    ns_write "<meta http-equiv=\"refresh\" content=\"0; URL=$return_url\">"
} else {
    ad_returnredirect $return_url
}
