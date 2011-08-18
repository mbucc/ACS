# /file-storage/download.tcl
#
# by aure@arsdigita.com July 1999
#
# see if this person is authorized to read the file in question
# guess the MIME type from the original client filename
# have the Oracle driver grab the BLOB and write it to the connection
#
# modified by randyg@arsdigita.com, January 2000 to use the general
# permissions module
#
# $Id: download.tcl,v 3.1 2000/03/11 06:48:17 aure Exp $

ad_page_variables {
    {version_id ""}
}

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set exception_text ""
set exception_count 0

if [empty_string_p $version_id] {
    incr exception_count
    append exception_text "<li>No file was specified"
}

set group_id [ad_get_group_id]
if {$group_id == 0} {
    set group_id ""
}

if ![fs_check_read_p $db $user_id $version_id $group_id] {
    incr exception_count
    append exception_text "<li>You can't read this file"
}

## return errors
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

ReturnHeaders $file_type

ns_ora write_blob $db "
    select version_content 
    from   fs_versions
    where  version_id=$version_id"
