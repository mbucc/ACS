# /links/edit-3.tcl

ad_page_contract {
    Step 3 of 3 in editing a static page's link

    @param page_id The ID of the page to edit
    @param link_description The new description of the link
    @param link_title The new title of the link
    @param url The new link URL
    @param submit Whether the action is deleting or editing
    @param old_url The old link URL
    @param url_stub The URL of the static page the link is on
    @param contact_p Whether or not to inform user of link status

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id edit-3.tcl,v 3.2.2.6 2000/09/22 01:38:52 kevin Exp
} {
    page_id:notnull,naturalnum
    link_description:notnull
    link_title:notnull
    url:notnull
    submit:notnull
    old_url:notnull
    url_stub:notnull
    contact_p:notnull
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set user_id [ad_verify_and_get_user_id]

# get the page and author information

db_1row select_page_info "select url_stub, nvl(page_title, url_stub) as page_title, nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and static_pages.page_id = :page_id"

if { [regexp -nocase "delete" $submit] } {
    # user would like to delete
    db_1row select_link_info "select url, link_title, link_description from links where page_id = :page_id and url=:old_url and user_id=:user_id"]
    
    set page_content "[ad_header "Verify deletion"]
    
<h2>Verify Deletion</h2>
to <a href=\"$url_stub\">$page_title</a>

<hr>
Would you like to delete the following link?
<p>
<a href=\"$url\">$link_title</a> - $link_description
<p>
<form action=delete method=post>
[export_form_vars page_id url]
<center>
<input type=submit value=\"Delete Link\" name=submit>
<input type=submit value=\"Cancel\" name=submit>
</center>
</form>
[ad_footer]"
doc_return  200 text/html $page_content
return
}

#user would like to edit

if [catch {db_dml update_link "update links
set url=:url, link_title=:link_title, 
link_description=:link_description, contact_p=:contact_p
where page_id=:page_id 
and url=:old_url
and user_id = :user_id"} errmsg] {
    
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

set page_content  "[ad_header "Link edited"]

<h2>Link edited</h2>

on <a href=\"$url_stub\">$page_title</a>

<hr> 

The following link is listed as a related link on the page <a href=\"$url_stub\">$page_title</a> page. 
<blockquote>
<A href=\"$url\">$link_title</a> - $link_description
</blockquote>

[ad_footer]
"

doc_return 200 text/html $page_content

if [ad_parameter EmailEditedLink links] {
    # send email if necessary
    db_1row select_email_info "select first_names || ' ' || last_name as name, email from users where user_id = :user_id"]
    set_variables_after_query

    db_release_unused_handles

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
