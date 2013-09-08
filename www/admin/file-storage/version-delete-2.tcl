# version-delete-2.tcl

ad_page_contract {
    1) finds the id of the latest version of a file that is not being deleted (new_latest_id)
    2) updates all the old versions to point to this one (new_latest_id)
    3) updates the new latest to have a NULL superseded_id
    4) deletes the version to kill
    
    (note that if the version being deleted is NOT the latest one, we still do all of the
    preceding work but it doesn't have any effect)

    @author dh@arsdigita.com
    @creation-date July 1999
} {
    file_id:integer
    version_id:integer
    return_url
}

set exception_count 0
set exception_text ""

## does the file exist?
if { [empty_string_p $file_id] } {
    incr exception_count
    append exception_text "<li>No file was specified"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set new_newest_query {
    select max(version_id) 
    from fs_versions
    where file_id = :file_id
    and version_id <> :version_id
}

set new_latest_id [db_string unused $new_newest_query]

db_transaction {
    db_dml unused "update fs_versions set superseded_by_id = :new_latest_id where file_id = :file_id"
    db_dml unused "update fs_versions set superseded_by_id = NULL 
                   where version_id = :new_latest_id and file_id = :file_id"
    db_dml unused "delete from fs_versions where version_id = :version_id"
}

ad_returnredirect $return_url
