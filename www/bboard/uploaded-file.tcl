# /www/bboard/uploaded-file.tcl
ad_page_contract {
    Gets an uploaded file.

    @param bboard_upload_id the ID for the file

    @cvs-id uploaded-file.tcl,v 3.4.2.4 2000/07/21 03:58:53 ron Exp
} {
    bboard_upload_id:integer
}

# -----------------------------------------------------------------------------

set filename [db_string filename "
select client_filename
from bboard_uploaded_files 
where bboard_upload_id = :bboard_upload_id" -default ""]

if [empty_string_p $filename] {
    ad_return_error "Not Found" \
	"This file might be associated with a thread that was deleted by the forum moderator"
    return
}

regsub -all {[^-_.0-9a-zA-Z]+} $filename "_" filename

ad_returnredirect "download-file/$bboard_upload_id/$filename"

