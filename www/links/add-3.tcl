# /links/add-3.tcl

ad_page_contract {
    Step 3 of 3 in adding a link to a static page

    @param page_id
    @param link_description
    @param link_title
    @param url
    @param contact_p

    @author Tracy Adams (teadams@mit.edu)
    @author Philip Greenspun (philg@mit.edu)
    @creation-date mid-1998
    @cvs-id add-3.tcl,v 3.2.2.7 2000/09/22 01:38:51 kevin Exp
} {
    page_id:notnull,naturalnum
    link_description:
    link_title:
    url:
    contact_p:
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

set glob_patterns [db_list select_glob_patterns "select glob_pattern 
from link_kill_patterns
where page_id = :page_id
or page_id is null"]

foreach pattern $glob_patterns {
    if { [string match $pattern $url] } {
	ad_return_complaint 1 "<li>Your submission matched one of this community's exclusion patterns:

<blockquote>
<code>
$pattern
</code>
</blockquote>

These are installed by site administrators after noticing that someone is
posting unrelated links.
"
	return
    }
}

set originating_ip [ns_conn peeraddr]

set already_submitted_p 0

if [catch { db_dml insert_link "insert into links
(page_id, user_id, url, link_title, link_description, contact_p, status,
originating_ip, posting_time)
values (
:page_id, :user_id, :url, :link_title, :link_description, :contact_p, 'live', :originating_ip,SYSDATE)" } errmsg] {

    if { [db_string select_existing_link_p "select count(url) from links where page_id = :page_id and url=:url"] > 0 } {
	# the link was already there, either submitted by another user or this user pressed the button twice.
    	set already_submitted_p 1
    } else {

	# there was a different error, print an error message
	ad_return_error "Error inserting a link" "
There was an error in inserting your link into the database.
Here is what the database returned:
<p>
<pre>
$errmsg
</pre>

Don't quit your browser. The database may just be busy.
You might be able to resubmit your posting five or ten minutes from now.
"

    }
}

# get the page and author information

db_1row select_page_info "select url_stub, nvl(page_title,  url_stub) as page_title, nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and static_pages.page_id = :page_id"

set page_content "[ad_header "Link submitted"]

<h2>Link submitted</h2>

to <a href=\"$url_stub\">$page_title</a>

<hr> 

The following link is listed as a related link on the page <a href=\"$url_stub\">$page_title</a> page. 
<blockquote>
<A href=\"$url\">$link_title</a> - $link_description
</blockquote>
[ad_footer]"

doc_return  200 text/html $page_content

if { [ad_parameter EmailNewLink links]   && !$already_submitted_p } {    
    # send email if necessary
    db_1row select_email_info "select first_names || ' ' || last_name as name, email from users where user_id = :user_id"
    db_release_unused_handles
    set subject "link added to $url_stub"
    set body "
$name ($email) added a link to
[ad_url]$url_stub
($page_title)
		
URL: $url
Title:  $link_title
Description:

[wrap_string $link_description]
"
    if [catch { ns_sendmail $author_email $email $subject $body } errormsg ] {
	ns_log Warning "Error in sending email to $author_email on [ns_conn url]"

    }
}   
