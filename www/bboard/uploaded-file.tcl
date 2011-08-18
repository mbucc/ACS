# $Id: uploaded-file.tcl,v 3.0 2000/02/06 03:34:52 ron Exp $
set_the_usual_form_variables

# bboard_upload_id

set db [ns_db gethandle]

set filename [database_to_tcl_string_or_null $db "select filename_stub 
from bboard_uploaded_files 
where bboard_upload_id=$bboard_upload_id"]

if [empty_string_p $filename] {
    ad_return_error "Not Found" "This file might be associated with a thread that was deleted by the forum moderator"
    return
}

set filename [bboard_file_path]/$filename

ns_returnfile 200 [ns_guesstype $filename] $filename
