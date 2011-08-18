# $Id: add-3.tcl,v 3.0 2000/02/06 03:49:24 ron Exp $
#
# /links/add-3.tcl
#
# originally by Tracy Adams in mid-1998
# fixed up by philg@mit.edu on November 15, 1999
# to actually check link_kill_patterns before inserting
#

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# page_id, link_description, link_title, url, maybe contact_p

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set glob_patterns [database_to_tcl_list $db "select glob_pattern 
from link_kill_patterns
where page_id = $page_id
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

if [catch { ns_db dml $db "insert into links
(page_id, user_id, url, link_title, link_description, contact_p, status,
originating_ip, posting_time)
values (
$page_id, $user_id, '$QQurl', '$QQlink_title', '$QQlink_description', '$contact_p', 'live', '$originating_ip',SYSDATE)" } errmsg] {

    if { [database_to_tcl_string $db "select count(url) from links where page_id = $page_id and url='$QQurl'"] > 0 } {
	# the link was already there, either submitted by another user or this user pressed the button twice.
    	set already_submitted_p 1
    } else {

	# there was a different error, print an error message
	ReturnHeaders
	ns_write "[ad_header "Error in inserting a link"]
	
<h3> Error in inserting a link</h3>
<hr>
There was an error in inserting your link into the database.
Here is what the database returned:
<p>
<pre>
$errmsg
</pre>


Don't quit your browser. The database may just be busy.
You might be able to resubmit your posting five or ten minutes from now.

[ad_footer]"

    }
}

# get the page and author information

set selection [ns_db 1row $db "select url_stub, nvl(page_title,  url_stub) as page_title, nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and static_pages.page_id = $page_id"]
set_variables_after_query

ns_return 200 text/html "[ad_header "Link submitted"]

<h2>Link submitted</h2>

to <a href=\"$url_stub\">$page_title</a>

<hr> 

The following link is listed as a related link on the page <a href=\"$url_stub\">$page_title</a> page. 
<blockquote>
<A href=\"$url\">$link_title</a> - $link_description
</blockquote>
[ad_footer]"

if { [ad_parameter EmailNewLink links]   && !$already_submitted_p } {    
    # send email if necessary
    set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, email from users where user_id = $user_id"]
    set_variables_after_query
    ns_db releasehandle $db
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
