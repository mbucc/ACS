# www/admin/spam/upload-file-to-spam.tcl

ad_page_contract {

 Upload a message file directly into a spam message in the
 spam_history table

     @param spam_id id of this spam
     @param data_type html or text
     @param clientfile filename
     @param clientfile.tmpfile tmpfile on server


    @author hqm@arsdigita.com
    @cvs-id upload-file-to-spam.tcl,v 3.4.2.9 2000/09/18 08:46:58 hqm Exp
} {
    spam_id:integer
    data_type
    clientfile
    clientfile.tmpfile:tmpfile
 }


set exception_count 0
set exception_text ""

# let's first check to see if this user is authorized to attach
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


if { ![info exists clientfile] || [empty_string_p $clientfile] } {
    append exception_text "<li>Please specify a file to upload\n"
    incr exception_count
} else {
    # this stuff only makes sense to do if we know the file exists
    set tmp_filename ${clientfile.tmpfile}

    set n_bytes [file size $tmp_filename]

    if { $n_bytes == 0 } {
	append exception_text "<li>Your file is zero-length. Either you attempted to upload a zero length file, a file which does not exist, or something went wrong during the transfer.\n"
	incr exception_count
    }
}

# copy to the appropriate blob

switch $data_type {
    "plain" {
	set colname "body_plain"
    }
    "html" {
	set colname "body_html"
    }
    "aol" {
	set colname "body_aol"
    }
    default {
	ad_return_error "no content type supplied!"
	return
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if {[catch {db_dml write_spam_clob_to_db "update spam_history
            set $colname = empty_clob()
            where spam_id = :spam_id
            returning $colname into :1" -clob_files [list $tmp_filename]} errmsg]} {
    ad_return_error "Ouch!" "The database choked on your insert:
<blockquote>
$errmsg
<pre>data_type = $data_type 
colname = $colname
<pre>
</blockquote>
"
    return
}

ad_returnredirect "/admin/spam/spam-edit.tcl?[export_url_vars spam_id]"

