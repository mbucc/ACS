# $Id: edit-3.tcl,v 3.0 2000/02/06 03:49:30 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# page_id, link_description, page_title, url, summit, old_url

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

# get the page and author information

set selection [ns_db 1row $db "select url_stub, nvl(page_title, url_stub) as page_title, nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and static_pages.page_id = $page_id"]
set_variables_after_query

if { [regexp -nocase "delete" $submit] } {
    # user would like to delete
    set selection [ns_db 1row $db "select url, link_title, link_description from links where page_id = $page_id and url='$QQold_url' and user_id=$user_id"]
    set_variables_after_query
    
    ReturnHeaders
    ns_write "[ad_header "Verify deletion"]
    
<h2>Verify Deletion</h2>
to <a href=\"$url_stub\">$page_title</a>

<hr>
Would you like to delete the following link?
<p>
<a href=\"$url\">$link_title</a> - $link_description
<p>
<form action=delete.tcl method=post>
[export_form_vars page_id url]
<center>
<input type=submit value=\"Delete Link\" name=submit>
<input type=submit value=\"Cancel\" name=submit>
</center>
</form>
[ad_footer]"
return
}

#user would like to edit


if [catch {ns_db dml $db "update links
set url='$QQurl', link_title='$QQlink_title', 
link_description='$QQlink_description', contact_p='$contact_p'
where page_id=$page_id 
and url='$QQold_url'
and user_id = $user_id"} errmsg] {
    
	ad_return_error "Error in updating link" "There 
was an error in updating your link in the database.
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


ns_return 200 text/html  "[ad_header "Link edited"]

<h2>Link edited</h2>

on <a href=\"$url_stub\">$page_title</a>

<hr> 

The following link is listed as a related link on the page <a href=\"$url_stub\">$page_title</a> page. 
<blockquote>
<A href=\"$url\">$link_title</a> - $link_description
</blockquote>

[ad_footer]
"


if [ad_parameter EmailEditedLink links] {
    # send email if necessary
    set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, email from users where user_id = $user_id"]
    set_variables_after_query

    ns_db releasehandle $db

    set subject "edited link from $url_stub"
    set body "$name ($email) edited a link from
[ad_url]$url_stub
($page_title)

URL:  $url
Description:

[wrap_string $link_description]
"
    if [ catch { ns_sendmail $author_email $email $subject $body } errmsg] {
	ns_log Warning "Error in email to $author_email from [ns_conn url]"
    }
}
