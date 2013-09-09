# /file-storage/download.tcl

ad_page_contract {
    see if this person is authorized to read the file in question
    guess the MIME type from the original client filename
    have the Oracle driver grab the BLOB and write it to the connection

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id download.tcl,v 3.4.2.3 2000/07/27 21:22:13 jwong Exp

    modified by randyg@arsdigita.com, January 2000 to use the general
    permissions module
} {
    version_id:naturalnum,notnull
} -errors {
    version_id:notnull {No file was specified}
    version_id:naturalnum {The version_id specified doesn't look like an integer.}
}

set user_id [ad_maybe_redirect_for_registration]

set group_id [ad_get_group_id]
if {$group_id == 0} {
    set group_id ""
}

db_transaction {

if {![fs_check_read_p $user_id $version_id $group_id]} {
    ad_return_complaint 1 "You can't read this file"
    return 0
}

set file_type [db_string file_type "select file_type 
                                    from fs_versions 
                                    where version_id = :version_id"]
} on_error {
    ad_return_complaint 1 "Error occurred while retrieving file version $version_id."
}

ReturnHeaders $file_type

db_write_blob fs_blob_content_write "select version_content 
from   fs_versions
where  version_id=$version_id"

db_release_unused_handles
