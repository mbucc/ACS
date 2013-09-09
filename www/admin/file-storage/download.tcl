ad_page_contract {
    @cvs-id download.tcl,v 3.1.10.2 2000/07/25 11:27:54 ron Exp
} {
    version_id:integer
}

################
# Must check the user's privelages of downloading this file

set filename [db_string file_name_get "
select client_file_name 
from   fs_versions 
where  version_id=:version_id" -bind [ad_tcl_vars_to_ns_set version_id]]

ReturnHeaders [ns_guesstype $filename]

db_with_handle db {
    ns_ora write_blob $db "
	select version_content 
	from   fs_versions
	where  version_id=$version_id"
}

