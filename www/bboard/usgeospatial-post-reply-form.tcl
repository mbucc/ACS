# /www/bboard/usgeospatial-post-reply-form.tcl
ad_page_contract {
    Form to reply to a message

    @param refers_to the ID of the message being refered to 

    @cvs-id usgeospatial-post-reply-form.tcl,v 3.3.2.4 2000/09/22 01:36:58 kevin Exp
} {
    refers_to:notnull
}

# -----------------------------------------------------------------------------

page_validation {
    bboard_validate_msg_id $refers_to
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set form_refers_to $refers_to

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


if {! [db_0or1row original_message "
select users.first_names || ' ' || users.last_name as name, 
       bboard.*, 
       users.*  
from   bboard, 
       users 
where  users.user_id = bboard.user_id
and    msg_id = :form_refers_to"]} {

    # message was probably deleted
    doc_return  200 text/html "Couldn't find message $msg_id.  Probably the message to which you are currently trying to reply has deleted by the forum maintainer."
    return
}

if {![db_0or1row get_topic "
select unique * from bboard_topics where topic_id = :topic_id"]} {
    bboard_return_cannot_find_topic_page
    return
}


append page_content "
[bboard_header "Respond"]

<h2>Respond</h2>

to \"$one_line\"

<p>

in <a href=\"usgeospatial-2?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>

<hr>

<h3>Original Posting</h3>

$message

<p>

from $name (<a href=\"mailto:$email\">$email</a>)

<hr>

<form method=post action=\"insert-msg\">

<input type=hidden name=usgeospatial_p value=t>
<input type=hidden name=refers_to value=$form_refers_to>
<b>One-line</b> summary of response<p>
<blockquote>
<input type=text name=one_line size=65 value=\"Response to [philg_quote_double_quotes $one_line]\">
</blockquote>
<p>
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
<input type=hidden name=notify value=f>

<table>

<tr><th>Response<td> &nbsp;</tr>

</table>

<p>

<blockquote>

<textarea name=message rows=8 cols=70 wrap=hard></textarea>

</blockquote>

<p>

<center>
<input type=submit value=Respond>
</center>
</form>


[bboard_footer]
"

doc_return 200 text/html $page_content
