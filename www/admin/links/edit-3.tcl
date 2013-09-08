# /admin/links/edit-3.tcl

ad_page_contract {
    Step 3 in editing a link

    @param page_id The ID of the page the link is on
    @param link_description The new description of the link
    @param link_title The new title of the link
    @param url The new URL of the link
    @param old_url The old URL of the link
    @param contact_p Whether or not to contact the original author about link status

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id edit-3.tcl,v 3.1.2.6 2000/09/22 01:35:30 kevin Exp
} {
    page_id:notnull,naturalnum
    link_description:notnull
    link_title:notnull
    url:notnull
    old_url:notnull
    contact_p:notnull
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

# get the page and author information

db_1row select_page_and_author_info "select url_stub, page_title, nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and static_pages.page_id = :page_id"

if [catch {db_dml update_link "update links
set url=:url, 
    link_title=:link_title, 
    link_description=:link_description, 
    contact_p=:contact_p
where page_id=:page_id 
and url=:old_url"} errmsg] {
	ad_return_error "Error in updating link" "Here is what the database returned:
<p>
<pre>
$errmsg
</pre>
"
       return
}

set page_content "[ad_admin_header "Link edited"]

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

doc_return  200 text/html $page_content

if  [ad_parameter EmailEditedLink links] {

    # send email if necessary
	
    db_1row select_user_info "select first_names || ' ' || last_name as name, email from users where user_id = :user_id"

    db_release_unused_handles
    
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
