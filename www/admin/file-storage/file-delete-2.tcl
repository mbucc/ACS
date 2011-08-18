# $Id: file-delete-2.tcl,v 3.1.2.1 2000/04/28 15:09:00 carsten Exp $
set_the_usual_form_variables

# file_id, maybe group_id

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

set db [ns_db gethandle]

set owner_id [database_to_tcl_string $db "select owner_id from fs_files where file_id=$file_id"]
set group_id [database_to_tcl_string $db "select group_id from fs_files where file_id=$file_id"]
    

# is this a folder ? Get all its children
set folder_p [database_to_tcl_string $db "select folder_p from fs_files where file_id=$file_id"]
ns_db dml $db "begin transaction"

if {$folder_p=="t"} {

    set sql_query "
      select file_id
      from   fs_files
      connect by prior file_id = parent_id
      start with file_id = $file_id "

    set children_list [database_to_tcl_list $db $sql_query]
    set children_list [join $children_list ", "]
    
    set sql_real_delete_versions "
      delete from fs_versions
      where file_id in ($children_list)"

    set sql_real_delete "
      delete from  fs_files
      where  file_id in ( $children_list ) "
    
    
} else {
    set sql_real_delete_versions "
       delete from fs_versions
       where file_id = $file_id"
 
    set sql_real_delete "
       delete from fs_files
       where   file_id = $file_id"
}

ns_db dml $db $sql_real_delete_versions

ns_db dml $db $sql_real_delete

fs_order_files $db $owner_id $group_id

ns_db dml $db "end transaction"



ad_returnredirect $return_url










