# file-remove-2.tcl,v 1.1.2.1 2000/02/03 09:49:50 ron Exp

ad_page_contract {
    Removes a file

    @param file_id the file to remove
    @param the url to which to return after removal

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id file-remove-2.tcl,v 3.4.2.4 2000/07/21 03:59:42 ron Exp
} {
    {file_id:integer,notnull}
    {return_url:notnull}
}

if [catch {db_dml del_file "delete from events_file_storage
where file_id = :file_id"} errmsg] {
#do nothing
}

ad_returnredirect $return_url