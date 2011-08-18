# $Id: file-edit-2.tcl,v 3.1.2.2 2000/04/28 15:09:00 carsten Exp $
set_the_usual_form_variables

# file_id, return_url, maybe group_id (lots of things)
# parent_id


set db [ns_db gethandle]


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

set user_id [database_to_tcl_string $db "select owner_id from fs_files where file_id=$file_id"]
if { [info exists group_id] && ![empty_string_p $group_id]} {

    set check "select ad_group_member_p ( $user_id, $group_id ) from dual"

    if [catch { set check [database_to_tcl_string $db $check]} error_msg] {
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
set sql_test "select file_title
              from   fs_files
              where  file_id=$file_id
              and    owner_id=$user_id"
if { [ catch {database_to_tcl_string $db $sql_test} file_title] } {
    incr exception_count 
    append exception_text "<li>You do not own this file"
}


if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}
set folder_p [database_to_tcl_string $db "select folder_p from fs_files where file_id=$file_id"]


set file_insert "
     update  fs_files
     set     file_title = '$QQfile_title',
             parent_id=[ns_dbquotevalue $parent_id]
      where  file_id=$file_id
      and    owner_id=$user_id
"

    


ns_db dml $db "begin transaction"

if {[ catch { ns_db dml $db $file_insert } junk] } {
    ns_db dml $db "end transaction"
    ad_returnredirect $return_url
}

fs_order_files $db $user_id $group_id

ns_db dml $db "end transaction"

ad_returnredirect $return_url










