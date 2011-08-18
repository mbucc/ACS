# /file-storage/create-folder-2.tcl
#
# created by aure@arsdigita.com, July, 1999
#
# modified by randyg@arsdigita.com, January, 2000 to use the
# general permissions module
#
# this file creates a new folder
#
# $Id: create-folder-2.tcl,v 3.2.2.2 2000/04/28 15:10:27 carsten Exp $

ad_page_variables {
    {file_id}
    {file_title}
    {group_id ""}
    {parent_id}
    {public_p "f"}
    {return_url}
    {version_id}
} 

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle]


# check the user input first

set exception_text ""
set exception_count 0

if [empty_string_p $file_title] {
    append exception_text "<li>You must give a title to the folder\n"
    incr exception_count
}

if {$public_p == "t" && ![ad_parameter PublicDocumentTreeP fs]} {
    append exception_text "
        <li>[ad_system_name] does not support a public directory tree."
    incr exception_count
}


if ![empty_string_p $group_id] {

    set check [database_to_tcl_string $db "
        select ad_group_member_p ($user_id, $group_id) from dual"]

    if { [string compare $check "f"] == 0 } {
	append exception_text "<li>You are not a member of this group $group_id\n"
	incr exception_count
    }

} else {
    set group_id ""
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_insert "
insert into fs_files (
    file_id, 
    file_title, 
    owner_id, 
    parent_id, 
    folder_p,  
    sort_key, 
    depth, 
    public_p, 
    group_id)
values (
    $file_id, 
    '[DoubleApos $file_title]', 
    $user_id, 
    [ns_dbquotevalue $parent_id], 
    't', 
    0, 
    0, 
    '$public_p', 
    '[DoubleApos $group_id]')"

# now we want to insert a "dummy" version so that we can also create the permission
# records

set version_insert "
    insert into fs_versions
    (version_id, file_id, creation_date, author_id)
    values
    ($version_id, $file_id, sysdate, $user_id)"

ns_db dml $db "begin transaction"

if { [ catch { ns_db dml $db $file_insert 
               ns_db dml $db $version_insert
               ns_ora exec_plsql $db "begin
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('read', $version_id, 'FS_VERSIONS');
 :1 := ad_general_permissions.grant_permission_to_all_users
        ('comment', $version_id, 'FS_VERSIONS');
end;"
             } errmsg] } {
    # insert failed; let's see if it was because of duplicate submission
    if { [database_to_tcl_string $db "select count(*) from fs_files where file_id = $file_id"] == 0 } {
	ns_log Error "/file-storage/create-folder-2.tcl choked:  $errmsg"
	ad_return_error "Insert Failed" "The Database did not like what you 
	                 typed.  This is probably a bug in our code.  Here's what 
                         the database said:
	                 <blockquote>
                         <pre>$errmsg</pre>
	                 </blockquote>"
        return
    }

    ns_db dml $db "abort transaction"

    # we don't bother to handle the cases where there is a dupe submission
    # because the user should be thanked or redirected anyway
    ad_returnredirect $return_url

}


fs_order_files $db

ns_db dml $db "end transaction"

ad_returnredirect $return_url
