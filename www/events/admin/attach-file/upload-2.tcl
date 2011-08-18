# upload-2.tcl,v 1.2.2.1 2000/02/03 09:49:56 ron Exp
# upload-2.tcl
# 
# by mbryzek@arsdigita.com, January 2000
#
# upload a picture into a table and associate it with another table/id
# 

set_the_usual_form_variables
# upload_file, file_title, file_id, on_what_id, on_which_table, return_url

set db [ns_db gethandle]
# check the user input first

set exception_text ""
set exception_count 0

if { ![exists_and_not_null on_which_table] } {
    incr exception_count
    append exception_text "<li>No table was specified"
} 
if { ![exists_and_not_null on_what_id] } {
    incr exception_count
    append exception_text "<li>No ID was specified"
} 
if { ![exists_and_not_null file_id] } {
    incr exception_count
    append exception_text "<li>No fileument ID was specified"
} 
if { ![exists_and_not_null file_title] } {
    incr exception_count
    append exception_text "<li>No fileument title was specified"
} 

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# get the file from the user.
# number_of_bytes is the upper-limit
# on the size of the file we will read. 1024*1024*2= 2097142
set max_n_bytes [ad_parameter MaxNumberOfBytes fs]

set tmp_file_name [ns_queryget upload_file.tmpfile]
set file_content [read [open $tmp_file_name] $max_n_bytes]

set file_extension [string tolower [file extension $upload_file]]
# remove the first . from the file extension
regsub "\." $file_extension "" file_extension

# Guess a mime type for this file.

set guessed_file_type [ns_guesstype $upload_file]

set n_kbytes [expr [file size $tmp_file_name] / 1024]

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^/\\]+)$} $upload_file match client_file_name] {
    # couldn't find a match
    set client_file_name $upload_file
}

set file_insert "
insert into events_file_storage
(file_id, file_title, file_content, client_file_name, file_type, file_extension, on_which_table, on_what_id, file_size, created_by, creation_ip_address, creation_date)
values
($file_id, '$QQfile_title', empty_blob(), '[DoubleApos $client_file_name]', '$guessed_file_type', '$file_extension', '$QQon_which_table', '$QQon_what_id', $n_kbytes, [ad_get_user_id], '[DoubleApos [ns_conn peeraddr]]', sysdate)
returning file_content into :1
"

ns_ora blob_dml_file $db $file_insert $tmp_file_name

# (version_id, file_id, version_description, creation_date, author_id, client_file_name, file_type, file_extension, n_kbytes, file_content)
# values
# ($version_id, $file_id, '$QQversion_description', sysdate, $user_id, '[DoubleApos $client_file_name]', '$guessed_file_type', '$file_extension', $n_bytes, empty_blob())
# returning file_content into :1" 


if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "success.tcl?[export_url_vars on_what_id on_which_table]"
}

