# /www/bboard/q-and-a-post-reply-form.tcl
ad_page_contract {
    Form to reply to a posting

    @param refers_to the message being replied to

    @author philg@arsdigita.com
    @author hqm@arsdigita.com
    @cvs-id q-and-a-post-reply-form.tcl,v 3.2.6.5 2000/09/22 01:36:52 kevin Exp
} {
    refers_to:notnull
}

# -----------------------------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if { ![db_0or1row original_message "
select users.user_id, 
       users.first_names || ' ' || users.last_name as name, 
       bboard.topic_id, 
       bboard_topics.topic, 
       bboard.category, 
       bboard.one_line, 
       bboard.message, 
       bboard.html_p
from   bboard, users, bboard_topics
where  bboard_topics.topic_id = bboard.topic_id 
and    users.user_id = bboard.user_id
and    msg_id = :refers_to"] } {

    # message was probably deleted
    doc_return  200 text/html "Couldn't find message $refers_to.  Probably the message to which you are currently trying to reply has deleted by the forum maintainer."
    return
}

if {![db_0or1row topic_info "
select unique * from bboard_topics where topic_id=:topic_id"]} {
    bboard_return_cannot_find_topic_page
    return
}


append page_content "
[bboard_header "Post Answer"]


<h3>Post an Answer</h3>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Post Answer"]

<hr>

<h3>Original question</h3>

<blockquote>
Subject: $one_line
<br>
<br>
[util_maybe_convert_to_html $message $html_p]
<br>
<br>
-- [ad_present_user $user_id $name]
</blockquote>

<h3>Your Response</h3>

<blockquote>
<form method=post action=\"confirm\">
[export_form_vars topic topic_id category]
<input type=hidden name=q_and_a_p value=t>
<input type=hidden name=refers_to value=$refers_to>
<input type=hidden name=notify value=f>


<b>Subject:</b>
<br>
<input type=text name=one_line size=70 value=\"Response to [philg_quote_double_quotes $one_line]\">

<p>


<b>Answer:</b>

<br>

<textarea name=message rows=8 cols=70 wrap=physical></textarea>

<p>
The above text is:
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>

<br><br>
<center>
<input type=submit value=Submit>
</center>
</form>
</blockquote>
</body>
</html>
"

doc_return 200 text/html $page_content





