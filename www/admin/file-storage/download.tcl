# $Id: download.tcl,v 3.1 2000/03/11 23:09:34 aure Exp $

set_the_usual_form_variables

# version_id

################
# Must check the user's privelages of downloading this file

set db [ns_db gethandle]

set filename [database_to_tcl_string $db "
select client_file_name 
from   fs_versions 
where  version_id=$version_id"]

ReturnHeaders [ns_guesstype $filename]

ns_ora write_blob $db "select version_content 
                       from   fs_versions
                       where  version_id=$version_id" 

