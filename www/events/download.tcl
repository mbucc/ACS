# Download a file

set_the_usual_form_variables 
# form_id

set db [ns_db gethandle]
set file_type [database_to_tcl_string $db \
	"select file_type
           from events_file_storage
          where file_id=$file_id"]

ReturnHeaders $file_type

ns_ora write_blob $db "select file_content 
                       from   events_file_storage
                       where  file_id=$file_id" 
