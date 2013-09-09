# download.tcl,v 1.2.2.1 2000/02/03 09:49:48 ron Exp
# Download a file

ad_page_contract {
    download a file

    @param file_id the file to download

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id download.tcl,v 3.2.10.3 2000/07/21 03:59:42 ron Exp
} {
    {file_id:integer,notnull}
}


set file_type [db_string download_file \
	"select file_type
           from events_file_storage
          where file_id=:file_id"]

ReturnHeaders $file_type

db_write_blob write_file "select file_content 
from events_file_storage
where file_id=$file_id" 

db_release_unused_handles
