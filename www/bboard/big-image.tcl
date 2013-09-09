# /www/bbaord/big-image.tcl
ad_page_contract {
    Displays a picture associated with some bboard posting

    @param bboard_upload_id the ID for the picture

    @cvs-id big-image.tcl,v 3.0.12.4 2000/09/22 01:36:48 kevin Exp
} {
    bboard_upload_id:integer
}

# -----------------------------------------------------------------------------

if { ![db_0or1row upload_info "
select buf.msg_id, 
       caption, 
       original_width, 
       original_height, 
       bboard.sort_key
from   bboard_uploaded_files buf, 
       bboard 
where  bboard.msg_id = buf.msg_id
and    bboard_upload_id=:bboard_upload_id"] } {

    ad_return_error "Couldn't find image" "Couldn't find image.  Perhaps it has been deleted by the moderator?"
    return
}

if { [string first "." $sort_key] == -1 } {
    # there is no period in the sort key so this is the start of a thread
    set thread_start_msg_id $sort_key
} else {
    # strip off the stuff before the period
    regexp {(.*)\..*} $sort_key match thread_start_msg_id
}

db_1row topic_info "
select topic_id, topic, presentation_type 
from bboard_topics 
where topic_id = (select topic_id from bboard where msg_id = :msg_id)"

db_release_unused_handles 

if { ![empty_string_p $original_width] && ![empty_string_p $original_height] } {
    set extra_img_tags "width=$original_width height=$original_height"
} else {
    set extra_img_tags ""
}

doc_return  200 text/html "[bboard_header "One BBoard Photo"]

<h2>$caption</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] [list [bboard_msg_url $presentation_type $thread_start_msg_id $topic_id] "One Thread"] "Big Image"]

<hr>

<center>
<IMG $extra_img_tags src=\"image.tcl?bboard_upload_id=$bboard_upload_id\">
<h4>$caption</h4>
</center>


</body>
</html>
"
