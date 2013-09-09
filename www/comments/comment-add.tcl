# www/comments/comment-add.tcl

ad_page_contract {
    @author teadams@mit.edu 
    @creation-date mid-1998
    @param page_id
    @param message
    @param comment_type
    @param comment_id
    @param rating
    @param html_p
    @cvs-id comment-add.tcl,v 3.2.2.8 2000/10/05 19:49:26 sklein Exp
} {
    page_id:naturalnum
    message:html
    comment_type
    comment_id:naturalnum
    {rating 0}
    {html_p "f"}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


if { [info exists html_p] && $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $message]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $message]\n"
    return
}

set originating_ip [ns_conn peeraddr]
set user_id [ad_get_user_id]
set already_submitted_p 0

if { [catch { 
    db_dml comment_insert "insert into comments
    (comment_id,page_id, user_id, comment_type, message, rating, originating_ip, posting_time, html_p)
    values ($comment_id,$page_id, $user_id, '[DoubleApos $comment_type]', empty_clob(), '[export_var rating]', '$originating_ip', SYSDATE, '[export_var html_p]') 
    returning message into :1" -clobs [list $message] } errmsg] } {

    if { [db_string double_click_check "select count(comment_id) from comments where comment_id = :comment_id" ] > 0 } {
	# the comment was already there; user must have double clicked
	set already_submitted_p 1
    } else {
	# there was some other error with the comment insert
	ad_return_error "Error in inserting comment" " There was an 
error in inserting your comment into the database.
Here is what the database returned:
<p>
<pre>
$errmsg
</pre>

Don't quit your browser. The database may just be busy.
You might be able to resubmit your posting five or ten minutes from now.
"
    return
    }
}   

# comment is submitted, find out the page information
# if there is no title, we use the url stub
# if there is no author, we use the system owner

set selection [db_0or1row page_data_get "
select nvl(page_title,url_stub) as page_title, url_stub,  nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and page_id = :page_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not be found."
    db_release_unused_handles
    return
}

set selection [db_0or1row user_name_get "select first_names || ' ' || last_name as name, email from users 
                       where user_id = :user_id"]
if {$selection == 0} {
    ad_return_complaint "Invalid user id" "User id could not be found."
    db_release_unused_handles
    return
}

db_release_unused_handles

switch $comment_type {
	
    "unanswered_question" {
	set subject  "question about $url_stub" 
	set email_body  "
$name ($email) asked a question about
[ad_url]$url_stub
($page_title):
		
QUESTION: 

[wrap_string $message]
"
        set confirm_body "Your question, as appears below, has been recorded and will be considered for page modifications or new site content."
    }
    
    "alternative_perspective" {
	set subject "comment on $url_stub"  
	set email_body "
$name ($email) gave an alternative perspective on
[ad_url]$url_stub
($page_title):
		
[wrap_string $message]
"
        set confirm_body "Your comment, as it appears below, has been added and will be seen as part of the <a href=\"$url_stub\">$page_title</a> page."
     }
		
     "rating" {
	 set subject  "$url_stub rated $rating"
	 set email_body  "
$name ($email) rated
[ad_url]$url_stub
($page_title)
	     
RATING: $rating

[wrap_string $message]
"
         set confirm_body "Your rating of \"<b>$rating</b>\" has been submitted along with the comment below and will be considered for page modifications or new site content."
    }
}

if { $html_p == "t" } {
    set message_for_presentation $message
} else {
    set message_for_presentation [util_convert_plaintext_to_html $message]
}


doc_return  200 text/html "[ad_header "Comment submitted"]

<h2>Comment submitted</h2>

to <a href=\"$url_stub\">$page_title</a>

<hr> 
$confirm_body
<p>
<blockquote>
$message_for_presentation
</blockquote>
<p>
Return to  <a href=\"$url_stub\">$page_title</a>

<P>

Alternatively, you can attach a
file to your comment.  This file can be a document, a photograph, or
anything else on your desktop computer.

<form enctype=multipart/form-data method=POST action=\"upload-attachment\">
[export_form_vars comment_id url_stub]
<blockquote>
<table>
<tr>
<td valign=top align=right>Filename: </td>
<td>
<input type=file name=upload_file size=20><br>
<font size=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".</font>
</td>
</tr>
<tr>
<td valign=top align=right>Caption</td>
<td><input size=30 name=caption>
<br>
<font size=-1>(leave blank if this isn't a photo)</font>
</td>
</tr>
</table>
<p>
<center>
<input type=submit value=\"Upload\">
</center>
</blockquote>
</form>

[ad_footer]"


# Send the author email if necessary, sent from the system owner in case of bounces
set sender_email [ad_system_owner]

if { [send_author_comment_p $comment_type add] && !$already_submitted_p } {
    # send email if necessary    
    catch { ns_sendmail $author_email $sender_email $subject $email_body }
}

### EOF
