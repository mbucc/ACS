# /www/bboard/image.tcl
ad_page_contract {
    Serves a file associated with a bboard post

    @param bboard_upload_id the ID of the file

    @cvs-id image.tcl,v 3.1.2.4 2000/09/22 01:36:50 kevin Exp
} {
    bboard_upload_id:integer
}

# -----------------------------------------------------------------------------


set filename [db_string filename "
select filename_stub from bboard_uploaded_files 
where bboard_upload_id=:bboard_upload_id"]

set filename [bboard_file_path]/$filename

ad_returnfile 200 [ns_guesstype $filename] $filename
