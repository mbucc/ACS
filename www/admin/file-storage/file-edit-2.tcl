# file-edit-2.tcl
ad_page_contract {
    @cvs-id file-edit-2.tcl,v 3.4.2.2 2000/07/25 11:27:54 ron Exp
} {
    file_id:integer
    file_title
    return_url
    {group_id ""}
    parent_id:integer
}

# check the user input first

set exception_text ""
set exception_count 0

if { ![info exists file_title] || [empty_string_p $file_title] } {
    append exception_text "<li>You must give a title to the file\n"
    incr exception_count
}

if {![info exists return_url]} {
    append exception_text "<li>The return url was missing"
    incr exception_count
}

set user_id [db_string unused "select owner_id from fs_files where file_id=:file_id"]

if { [info exists group_id] && ![empty_string_p $group_id]} {

    set check "select ad_group_member_p ( :user_id, :group_id ) from dual"

    if [catch { set check [db_string unused $check]} error_msg] {
	append exception_text "<li>You are not a member of this group $group_id \n"
	incr exception_count
    }
} else {
    set group_id ""
}
## does the file exist?
if {(![info exists file_id])||([empty_string_p $file_id])} {
    incr exception_count
    append exception_text "<li>No file was specified"
}
## does user_id own the file?
set sql_test "select 1 as one
              from   fs_files
              where  file_id=:file_id
              and    owner_id=:user_id"

if { [db_0or1row test $sql_test]==0 } {
    incr exception_count 
    append exception_text "<li>You do not own this file"
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}
set folder_p [db_string unused "select folder_p from fs_files where file_id=:file_id"]

set file_insert {
    update  fs_files
    set     file_title = :file_title,
            parent_id  = :parent_id
    where   file_id    = :file_id
    and     owner_id   = :user_id
}


db_transaction {
    db_dml file_update $file_insert
    fs_order_files $user_id $group_id
}

ad_returnredirect $return_url
