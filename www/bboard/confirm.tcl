# /www/bboard/confirm.tcl
ad_page_contract {
    display a confirmation page for new news postings
    
    @param topic_id - the topic id
    @param one_line - one line description of data
    @param message - body of message

    @author phil (philg@arsdigita.com)
    @cvs-id confirm.tcl,v 3.3.6.11 2000/11/11 00:50:44 lars Exp
} {
    topic_id:integer
    one_line:notnull
    message:allhtml,notnull
    notify
    {html_p "f"}
    refers_to
    {category ""}
    {uploads_anticipated ""}
} -validate {
    html_p_ok { 
	if { ![string equal $html_p "t"] && ![string equal $html_p "f"] } {
	    ad_complain "html_p should be 't' for html-format, or 'f' for plaintext"
	}
    }
    html_security_check -requires { message:notnull } {
	if { [string equal $html_p "t"] } { 
	    set security_check [ad_html_security_check $message]
	    if { ![empty_string_p $security_check] } {
		ad_complain $security_check
	    }
	}
    }
}

# -----------------------------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if {[bboard_get_topic_info] == -1} {
    return
}

db_1row bb_conf_presentation {
    select presentation_type
    , q_and_a_cats_user_extensible_p 
    from bboard_topics 
    where topic_id = :topic_id
} 

append page_content "[bboard_header "Confirm"]
<h2>Confirm</h2>
[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Confirm Posting"]
<hr>
<blockquote>
Subject: $one_line
<br>
<br>
[ad_convert_to_html -html_p $html_p -- $message]
"

if { $html_p == "t" } {
    append page_content "
    </blockquote>
    Note: if the story has lost all of its paragraph breaks then you
    probably should have selected \"Plain Text\" rather than HTML.  Use
    your browser's Back button to return to the submission form.
    "
} else {
    append page_content "
    </blockquote>
    
    Note: if the story has a bunch of visible HTML tags then you probably
    should have selected \"HTML\" rather than \"Plain Text\".  Use your
    browser's Back button to return to the submission form.  " 
}

    
# (bran Apr 4 2000)
if {$q_and_a_cats_user_extensible_p == "t" && [empty_string_p $category]} {
    set add_category_form_piece "
    <center>
    <table bgcolor=#EEEEEE width=80% cellspacing=5 cellpadding=5>
    <tr>
    <td>
    You may define a category for your posting:
    <INPUT TYPE=text name=category><br>
    </td>
    </tr>
    </table>
    </center>"
} else {
    set add_category_form_piece ""
}

if {![bboard_file_uploading_enabled_p] || [empty_string_p $uploads_anticipated]} {
    set extra_form_tag ""
    set extra_form_contents ""
} elseif { [bboard_file_uploading_enabled_p] && $uploads_anticipated == "images" } {
    set extra_form_tag "enctype=multipart/form-data"
    set extra_form_contents "
    <center>
    <table bgcolor=#EEEEEE cellpadding=5 width=80%>
    <tr><td colspan=2 align=center>You may upload an image with this posting.</td></tr>
    <tr>
    <th>
    Filename 
    <td>
    <INPUT TYPE=file name=upload_file>
    <br>
    (<font size=-1>on your local hard drive</font>)
    </tr>
    <tr>
    <th>
    Caption
    <td><INPUT TYPE=text name=caption size=50>
    </tr>
    <tr><td>&nbsp;
    <td>
    <blockquote>
    <i>Note:  GIF and JPEG images are the only ones that can be displayed by most browsers.  So if the file you're uploading doesn't end in .jpg, .jpeg, or .gif it probably won't be viewable by most users.
    </i>
    </blockquote>
    </td>
    </tr>
    </table>
    </center><p>"
} elseif { [bboard_file_uploading_enabled_p] && $uploads_anticipated == "files" } {
    set extra_form_tag "enctype=multipart/form-data"
    set extra_form_contents "
    <p>
    You may upload a file with this posting: 
    <INPUT TYPE=file name=upload_file>
    <p>" 
} elseif { [bboard_file_uploading_enabled_p] && $uploads_anticipated == "images_or_files" } {
    set extra_form_tag "enctype=multipart/form-data"
    set extra_form_contents "
    <center>
    <table bgcolor=#EEEEEE width=80% cellspacing=5 cellpadding=5>
    <tr>
    <td>
    You may upload a file or image with this posting: 
    <INPUT TYPE=file name=upload_file><br>
    if this is an image, you can indicate
    that by typing in a caption: <INPUT TYPE=text name=caption size=50 maxlength=50>
    <p>
    <i>Note:  GIF and JPEG images are the only ones that can be displayed by most browsers.  So if the file you're uploading doesn't end in .jpg, .jpeg, or .gif it probably won't be viewable by most users.
    </i>
    </td>
    </tr>
    </table>
    </center>
    <p>" 
} else {
    append page_content "Oops!  We're confronted with uploads_anticipated of \"$uploads_anticipated\".
    
    <p>
    We don't know what to do with this.
    [bboard_footer]
    "
    doc_return  200 text/html $page_content
    return
}
    
# we will pass the entire form forward to the next
# page.  THerefore, we must delete urgent_p from ns_conn form
# so it doesn't get sent twice

ns_set delkey [ns_conn form] urgent_p
if ![info exists urgent_p] {
    set urgent_p "f"
}
    
append page_content "
<form $extra_form_tag method=post action=\"insert-msg\">
[export_form_vars message one_line notify html_p topic_id topic refers_to]

$add_category_form_piece
$extra_form_contents
"

if { $refers_to == "NEW" && [ad_parameter UrgentMessageEnabledP "bboard" 0] } {
    append page_content "
    <p>
    You can elect to mark this message urgent.  For 
    [ad_parameter DaysConsideredUrgent bboard]
    days after posting, your question will be put in front of other users.
    
    <p>
    
    Is this really urgent?
    <select name=\"urgent_p\">
    [html_select_value_options [list {"f" "no"} {"t" "yes"}] $urgent_p]</select>
    "
    
} else {
    append page_content "[export_form_vars urgent_p]\n"
}

append page_content "<center>
<input type=submit value=\"Confirm\">
</center>
</form>
</body>
</html>
"
doc_return 200 text/html $page_content
