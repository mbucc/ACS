# $Id: edit-3.tcl,v 3.0 2000/02/06 03:24:38 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# page_id, link_description, page_title, url, old_url

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

# get the page and author information

set selection [ns_db 1row $db "select url_stub, page_title, nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and static_pages.page_id = $page_id"]
set_variables_after_query

if [catch {ns_db dml $db "update links
set url='$QQurl', 
    link_title='$QQlink_title', 
    link_description='$QQlink_description', 
    contact_p='$contact_p'
where page_id=$page_id 
and url='$QQold_url'"} errmsg] {
	ad_return_error "Error in updating link" "Here is what the database returned:
<p>
<pre>
$errmsg
</pre>
"
       return
}


ns_return 200 text/html  "[ad_admin_header "Link edited"]

<h2>Link edited</h2>

from <a href=\"$url_stub\">$url_stub</a>

<hr> 

Here's what we've got in the database now:

<ul>
<li>Url:  <a href=\"$url\">$url</a>
<li>Title:  $link_title
<li>Description:  $link_description
</ul>

[ad_admin_footer]
"


if  [ad_parameter EmailEditedLink links] {

    # send email if necessary
	
    set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, email from users where user_id = $user_id"]
    set_variables_after_query

    ns_db releasehandle $db
    
    set subject "$email edited a link from $url_stub"
    set body "$name ($email) edited a related link to 
[ad_url]/$url_stub:

Url:  $url
Title: $link_title
Description:
$link_description
"
    if [ catch { ns_sendmail $author_email $email $subject $body } errmsg] {
	ns_log Warning "Error in email to $author_email from [ns_conn url]"
    }
}
