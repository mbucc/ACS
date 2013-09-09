# file-delete-2.tcl
ad_page_contract {
    @cvs_id file-delete-2.tcl,v 3.3.2.2 2000/07/25 11:27:54 ron Exp
} {
    file_id:integer
    {group_id ""}
}

set return_url index.tcl

set exception_count 0
set exception_text ""

## does the file exist?
if {(![info exists file_id])||([empty_string_p $file_id])} {
    incr exception_count
    append exception_text "<li>No file was specified"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}


set owner_id [db_string unused "select owner_id from fs_files where file_id=:file_id"]
set group_id [db_string unused "select group_id from fs_files where file_id=:file_id"]


# is this a folder ? Get all its children
set folder_p [db_string unused "select folder_p from fs_files where file_id=:file_id"]
db_transaction {

if {$folder_p=="t"} {

    set sql_query "
      select file_id
      from   fs_files
      connect by prior file_id = parent_id
      start with file_id = :file_id "
    set bind_vars [ad_tcl_vars_to_ns_set file_id]

    set children_list [db_list unused $sql_query -bind $bind_vars]
    set children_list [join $children_list ", "]
    
    set sql_real_delete_versions "
      delete from fs_versions
      where file_id in (:children_list)"

    set sql_real_delete "
      delete from  fs_files
      where  file_id in (:children_list ) "
    
    set bind_vars [ad_tcl_vars_to_ns_set children_list]
} else {
    set sql_real_delete_versions "
       delete from fs_versions
       where file_id = :file_id"
 
    set sql_real_delete "
       delete from fs_files
       where   file_id = :file_id"

    set bind_vars [ad_tcl_vars_to_ns_set file_id]
}

db_dml unused $sql_real_delete_versions -bind $bind_vars
db_dml unused $sql_real_delete -bind $bind_vars

fs_order_files $owner_id $group_id

}

ad_returnredirect $return_url

