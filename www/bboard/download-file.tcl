# /www/bboard/download-file
ad_page_contract {
    Page to let people download a file associated with a bboard posting

    @param bboard_upload_id the ID of the file to download

    @cvs-id download-file.tcl,v 3.3.2.4 2000/09/05 18:05:15 kevin Exp
} {
    bboard_upload_id:integer,notnull
}

# -----------------------------------------------------------------------------


page_validation {
    if ![db_0or1row filename "
    select filename_stub 
    from bboard_uploaded_files 
    where bboard_upload_id=:bboard_upload_id"] {
	error "File Not Found : This file might be associated with a thread that was deleted by the forum moderator"
    }
}

regsub -all {[^-_.0-9a-zA-Z]+} $filename_stub "_" filename_stub

ad_returnredirect "download-file/$bboard_upload_id/$filename_stub"
