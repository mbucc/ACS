# /www/bboard/unified/add-icon-2.tcl
ad_page_contract {
    Adds an icon.

    @param topic_id the ID of the bboard topic
    @param topic the name of the bboard topic
    @param upload_file the file containing the icon
    @param img_name the name to give the icon
    @param img_h the height of the image
    @param img_w the width of the image

    @author LuisRodriguez@photo.net
    @creation-date May 2000
} { 
    topic_id:integer,notnull
    topic
    upload_file:notnull
    img_name:notnull
    img_h:integer,notnull
    img_w:integer,notnull
}

# -----------------------------------------------------------------------------

ad_maybe_redirect_for_registration

set icon_dir [ad_parameter IconDir "bboard/unified" ""]

# remove the first . from the file extension
set file_extension [string tolower [file extension $upload_file]]
regsub "\." $file_extension "" file_extension

# check to see if this is one of the favored MIME types,
# e.g., image/gif or image/jpeg
set guessed_file_type [ns_guesstype $upload_file]

set tmp_filename [ns_queryget upload_file.tmpfile]
set n_bytes [file size $tmp_filename]

page_validation {
    if { [empty_string_p $icon_dir] } {
    ns_log Error "Error: bboard/unified/add-icon-2: no IconDir directory was specified to store more icons..."
	error "Sorry, no IconDir directory was specified as a publishing option as the place to store more icons.  You could complain to the system owner: <a href=\"mailto:[bboard_system_owner]\">[bboard_system_owner]</a>"
    }

    if { ![empty_string_p [ad_parameter AcceptablePortraitMIMETypes "user-info"]] && [lsearch [ad_parameter AcceptablePortraitMIMETypes "user-info"] $guessed_file_type] == -1 } {
        error "Your image wasn't one of the acceptable MIME types:   [ad_parameter AcceptablePortraitMIMETypes "user-info"]"
    }

    if { ![empty_string_p [ad_parameter MaxPortraitBytes "user-info"]] && $n_bytes > [ad_parameter MaxPortraitBytes "user-info"] } {
        error "Your file is too large.  The publisher of [ad_system_name] has chosen to limit icon images to [util_commify_number [ad_parameter MaxPortraitBytes "user-info"]] bytes.  You can use PhotoShop or the GIMP (free) to shrink your image.\n"
    }
}

set icon_id [db_string next_icon_id "
SELECT icon_id_seq.nextval
FROM dual
"]

# Try to set the file extension if it is a jpg or gif
if { $guessed_file_type == "image/gif"} {
    set file_extension "gif"
} elseif { $guessed_file_type == "image/jpeg"} {
    set file_extension "jpg"
}

set new_filename "Icon_$icon_id"
set fully_q_filename "$icon_dir/$new_filename.$file_extension"
if { !([catch [ns_cp $tmp_filename $fully_q_filename] errmsg] == 0) } {
    db_release_unused_handles
    ad_return_error "Could not copy icon to: $fully_q_filename from: $tmp_filename" "Here's what the error looked like:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return 0
}

if { [empty_string_p $img_name] } {
    set img_name $new_filename
}

append new_filename ".$file_extension"

db_dml icon_insert "
INSERT INTO bboard_icons
(icon_id, icon_file, icon_name, icon_width, icon_height)
 VALUES
(:icon_id, :new_filename, :img_name, :img_w, :img_h)"

db_release_unused_handles

ad_returnredirect customize-icon?[export_url_vars topic topic_id]