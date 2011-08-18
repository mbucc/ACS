# $Id: upload-2.tcl,v 3.0.4.1 2000/04/28 15:11:24 carsten Exp $
# 
# /pvt/portrait/upload-2.tcl
#
# by philg@mit.edu on September 26, 1999
#
# adds (or replaces) a user's portrait
# 

ad_maybe_redirect_for_registration

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set_the_usual_form_variables

# upload_file is the only required one; portrait_comment may be empty
# return_url (optional)

if { ![info exists QQportrait_comment] || [empty_string_p $QQportrait_comment] } {
    set complete_portrait_comment "NULL"
} else {
    set complete_portrait_comment "'$QQportrait_comment'"
}


set exception_text ""
set exception_count 0

if { ![info exists upload_file] || [empty_string_p $upload_file] } {
    append exception_text "<li>Please specify a file to upload\n"
    incr exception_count
} else {
    # this stuff only makes sense to do if we know the file exists
    set tmp_filename [ns_queryget upload_file.tmpfile]

    set file_extension [string tolower [file extension $upload_file]]

    # remove the first . from the file extension
    regsub "\." $file_extension "" file_extension

    set guessed_file_type [ns_guesstype $upload_file]

    set n_bytes [file size $tmp_filename]

    # check to see if this is one of the favored MIME types,
    # e.g., image/gif or image/jpeg
    if { ![empty_string_p [ad_parameter AcceptablePortraitMIMETypes "user-info"]] && [lsearch [ad_parameter AcceptablePortraitMIMETypes "user-info"] $guessed_file_type] == -1 } {
	incr exception_count
	append exception_text "<li>Your image wasn't one of the acceptable MIME types:   [ad_parameter AcceptablePortraitMIMETypes "user-info"]"
    }

    # strip off the C:\directories... crud and just get the file name
    if ![regexp {([^/\\]+)$} $upload_file match client_filename] {
	# couldn't find a match
	set client_filename $upload_file
    }

    if { ![empty_string_p [ad_parameter MaxPortraitBytes "user-info"]] && $n_bytes > [ad_parameter MaxPortraitBytes "user-info"] } {
	append exception_text "<li>Your file is too large.  The publisher of [ad_system_name] has chosen to limit portraits to [util_commify_number [ad_parameter MaxPortraitBytes "user-info"]] bytes.  You can use PhotoShop or the GIMP (free) to shrink your image.\n"
	incr exception_count
    }
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set what_aolserver_told_us ""
if { $file_extension == "jpeg" || $file_extension == "jpg" } {
    catch { set what_aolserver_told_us [ns_jpegsize $tmp_filename] }
} elseif { $file_extension == "gif" } {
    catch { set what_aolserver_told_us [ns_gifsize $tmp_filename] }
}

# the AOLserver jpegsize command has some bugs where the height comes 
# through as 1 or 2 
if { ![empty_string_p $what_aolserver_told_us] && [lindex $what_aolserver_told_us 0] > 10 && [lindex $what_aolserver_told_us 1] > 10 } {
    set original_width [lindex $what_aolserver_told_us 0]
    set original_height [lindex $what_aolserver_told_us 1]
} else {
    set original_width ""
    set original_height ""
}

ns_ora blob_dml_file $db "update users
set portrait = empty_blob(),
    portrait_comment = $complete_portrait_comment,
    portrait_client_file_name = '[DoubleApos $client_filename]',
    portrait_file_type = '[DoubleApos $guessed_file_type]',
    portrait_file_extension = '[DoubleApos $file_extension]',
    portrait_original_width = [ns_dbquotevalue $original_width number],
    portrait_original_height = [ns_dbquotevalue $original_height number],
    portrait_upload_date = sysdate
where user_id = $user_id
returning portrait into :1" $tmp_filename

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index.tcl"
}
