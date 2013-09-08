# /www/bboard/post-reply-form.tcl 

ad_page_contract {
    Page to add new topic
    @author unknown
    @creation-date unknown
    @cvs-id post-reply-form.tcl,v 3.4.2.4 2000/09/22 01:36:51 kevin Exp
} {
    refers_to:trim
} 

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

db_1row reply_info "
select first_names || ' ' || last_name as name, 
       bboard.one_line,
       bboard.topic_id, 
       bboard_topics.topic 
from   bboard, 
       users, 
       bboard_topics
where  users.user_id = bboard.user_id
and    bboard_topics.topic_id = bboard.topic_id
and    msg_id = :refers_to"

# release the database handle
db_release_unused_handles 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set page_content "
[bboard_header "Post Reply"]

<h3>Post a Reply</h3>

to \"$one_line\" from $name

<p>

in the <a href=\"main-frame?[export_url_vars topic topic_id]\" target=\"_top\">$topic</a> bboard

<hr>

<form method=post action=\"confirm\" target=\"_top\">

[export_form_vars topic topic_id]
<input type=\"hidden\" name=\"refers_to\" [export_form_value refers_to]>

<table>


<tr><th>Subject Line<td><input type=text name=one_line size=70 value=\"Response to [philg_quote_double_quotes $one_line]\"></tr>

<tr><th>Message<td><textarea name=message rows=6 cols=70 wrap=physical></textarea></tr>

<tr><th>Notify Me of Responses<br>(via email)
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No
</tr>
<tr><th align=left>Text above is:<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
</table>

<input type=submit value=Submit>

</form>

[bboard_footer]
"

doc_return  200 text/html $page_content











