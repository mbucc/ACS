ad_page_contract {
    Main page to display a page with 2 frames (top and bottom). 

    @param  topic_id - the topic id
    @param  topic - the topic
    @param  feature_msg_id - the feature msg id
    @param  start_msg-id - start message id

    @cvs-id main-frame.tcl,v 3.1.2.4 2000/09/22 01:36:51 kevin Exp
} {
    topic_id:integer,notnull
    topic
    {feature_msg_id ""}
    {start_msg_id ""}
}


if {![empty_string_p $feature_msg_id]} {
    set main_url "fetch-msg.tcl?msg_id=$feature_msg_id"
    set subject_url_appendage "&feature_msg_id=$feature_msg_id"
} else {
    # no featured msg
    set main_url "default-main.tcl?[export_url_vars topic topic_id]"
    set subject_url_appendage ""
}

if {![empty_string_p $start_msg_id]} {
    set subject_url "subject.tcl?[export_url_vars topic topic_id]&start_msg_id=$start_msg_id"
} else {
    set subject_url "subject.tcl?[export_url_vars topic topic_id]"
}

append subject_url $subject_url_appendage

# if we got here, that means the cookie checked

doc_return  200 text/html "

<html><base fontsize=3>

<head>

<title>$topic bboardl</title>

</head>
<frameset rows=\"25%,*\">
<frame scrolling=\"yes\" name=\"subject\" src=\"$subject_url\">
<frame scrolling=\"yes\" name=\"main\" src=\"$main_url\">
</frameset>

<noframe>

<body bgcolor=\"#ffffff\" text=\"#000000\">

this bulletin board system can only be used with a frames-compatible
browser.

<p>
perhaps you should consider running netscape 2.0 or later?

</body></html>

</noframel>

</frameset>

"



