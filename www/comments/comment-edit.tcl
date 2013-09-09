
ad_page_contract {
    actually updates the comments table (comments on static pages)
    
    @author teadams@mit.edu
    @creation-date mid-1998
    @param page_id
    @param message
    @param comment_type
    @param comment_id
    @param rating
    @param html_p
    @cvs-id comment-edit.tcl,v 3.0.12.7 2000/10/05 19:49:27 sklein Exp
} {
    page_id:naturalnum,notnull
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

if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $message]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $message]\n"
    return
}

# get the user_id
set user_id [ad_verify_and_get_user_id]


if { [catch { 
    db_dml coment_edit_update "update  comments 
    set  message = empty_clob(), rating='[export_var rating]', posting_time = SYSDATE, 
    html_p='[export_var html_p]' 
    where comment_id = $comment_id  and user_id=$user_id 
    returning message into :1" -clobs [list $message] } errmsg] } {
	# there was an error with the comment update
	ad_return_error "Error in updating comment" "
There was an error in updating your comment in the database.
Here is what the database returned:
<p>
<pre>
$errmsg
</pre>

Don't quit your browser. The database may just be busy.
You might be able to resubmit your posting five or ten minutes from now."

}

# page information
# if there is no title, we use the url stub
# if there is no author, we use the system owner

set selection [db_0or1row page_data_get "
select nvl(page_title,url_stub) as page_title, url_stub,  
nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and page_id = :page_id"]

if {$selection == 0} {
    ad_page_complaint "Invalid page id" "Page id could not be found"
    db_release_unused_handles
    return
}

set selection [db_0or1row user_name_get "
select first_names || ' ' || last_name as name, email 
from users where user_id = :user_id"]

if {$selection == 0} {
    ad_page_complaint "Invalid user id" "User id could not be found"
    db_release_unused_handles
    return
}

switch $comment_type {
	
    "unanswered_question" {
	set subject  "edited question about $url_stub" 
	set email_body  "
$name ($email) edited a question about 
[ad_url]$url_stub
($page_title):
		
QUESTION: 

[wrap_string $message]
"
        set confirm_body "Your modified question, as it appears below, has been recorded and will be considered for page modifications or new site content."
    }
    
    "alternative_perspective" {
	set subject "edited comment on $url_stub"
	set email_body "$name ($email) edited an alternative perspective on
[ad_url]$url_stub
($page_title):
		
[wrap_string $message]
"
        set confirm_body "Your modified comment, as it appears below, has been added and will be seen as part of the <a href=\"$url_stub\">$page_title</a> page."
     }
		
     "rating" {
	 set subject  "modified rating for $url_stub (to $rating)"  
	 set email_body  "
$name ($email) modified rating of
[ad_url]$url_stub
($page_title)
	     
RATING: $rating

[wrap_string $message]
"
         set confirm_body "Your modified rating of <b>$rating</b> has been submitted along with the comment below and will be considered for page modifications or new site content."
    }
}

if { [info exists html_p] && $html_p == "t" } {
    set message_for_presentation $message
} else {
    set message_for_presentation [util_convert_plaintext_to_html $message]
}

doc_return  200 text/html "[ad_header "Comment modified"]

<h2>Comment modified</h2>

on  <a href=\"$url_stub\">$page_title</a>.

<hr> 
$confirm_body
<p>
<blockquote>
$message_for_presentation
</blockquote>
<p>
Return to  <a href=\"$url_stub\">$page_title</a>
[ad_footer]"

# Send the author email if necessary, sent from the system owner in case of bounces
set sender_email [ad_system_owner]

if [send_author_comment_p $comment_type "edit"] {
    # send email if necessary    
    catch { ns_sendmail $author_email $sender_email $subject $email_body }
}

### EOF
