# file-remove-2.tcl,v 1.1.2.1 2000/02/03 09:49:50 ron Exp
set_the_usual_form_variables
#file_id, return_url

set db [ns_db gethandle]

if [catch {ns_db dml $db "delete from events_file_storage
where file_id = $file_id"} errmsg] {
#do nothing
}


ad_returnredirect $return_url