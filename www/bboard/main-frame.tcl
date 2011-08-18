# $Id: main-frame.tcl,v 3.0 2000/02/06 03:33:59 ron Exp $
set_form_variables

# topic_id, topic required
# feature_msg_id, start_msg_id optional

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if { [info exists feature_msg_id] && $feature_msg_id != "" } {
    set main_url "fetch-msg.tcl?msg_id=$feature_msg_id"
    set subject_url_appendage "&feature_msg_id=$feature_msg_id"
} else {
    # no featured msg
    set main_url "default-main.tcl?[export_url_vars topic topic_id]"
    set subject_url_appendage ""
}

if { [info exists start_msg_id] && $start_msg_id != "" } {
    set subject_url "subject.tcl?[export_url_vars topic topic_id]&start_msg_id=$start_msg_id"
} else {
    # no featured msg
    set subject_url "subject.tcl?[export_url_vars topic topic_id]"
}

append subject_url $subject_url_appendage

# if we got here, that means the cookie checked

ns_return 200 text/html "

<HTML><BASE F0NTSIZE=3>

<HEAD>

<TITLE>$topic BBoard</TITLE>

</HEAD>


<FRAMESET ROWS=\"25%,*\">

<FRAME SCROLLING=\"yes\" NAME=\"subject\" SRC=\"$subject_url\">

<FRAME SCROLLING=\"yes\" NAME=\"main\" SRC=\"$main_url\">

</FRAMESET>

<NOFRAME>

<BODY BGCOLOR=\"#FFFFFF\" TEXT=\"#000000\">

This bulletin board system can only be used with a frames-compatible
browser.

<p>

Perhaps you should consider running Netscape 2.0 or later?


</BODY></HTML>

</NOFRAME>

</FRAMESET>


"
