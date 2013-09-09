# /admin/links/edit-2.tcl

ad_page_contract {
    Step 2 in editing a link

    @param page_id The ID of the page the link came from
    @param old_url The old URL of the link
    @param link_description The new description of the link
    @param link_title The new title of the link
    @param contact_p Whether or not to contact the user if the link goes bad
    @param url The new URL of the link
    @param link_user_id The ID of the original creator of the link

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id edit-2.tcl,v 3.2.2.6 2000/09/22 01:35:30 kevin Exp
} {
    page_id:notnull,naturalnum
    old_url:notnull
    link_description:notnull
    link_title:notnull
    contact_p:notnull
    url:notnull
    link_user_id:notnull,naturalnum
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

db_1row select_page_info "select page_title, url_stub 
from static_pages
where page_id = :page_id"

# check for valid data

set exception_count 0
set exception_text ""

if { [string match $url "http://"] ==  1 } {
    # the user left the default hint for the url
    incr exception_count
    append exception_text "<li>Please type in a URL."
}

if {![philg_url_valid_p $url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    append exception_text "<li>You URL doesn't have the correct form.  A valid URL would be something like \"http://photo.net/philg/\"."
}

if { [string length $link_description] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit your link description to 4000 characters."
}

set sql_url "[string tolower $url]"
if { [db_string select_url_exists "select count(url) 
from links 
where page_id = :page_id
and lower(url)=:sql_url
and user_id <> :link_user_id"] > 0  } {
    # another user has submitted this link
    incr exception_count
    append exception_text "<li>$url was already submitted as a related link to this page by another user."
}

db_release_unused_handles

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# data are valid, move on

set page_content "[ad_admin_header "Confirm link from <i>$url_stub</i>" ]

<h2>Confirm link</h2>

from <a href=\"$url_stub\">$url_stub</a>

<hr>

The following is the link as it will appear on the page $url_stub
(<i>$page_title</i>).

If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Proceed\".

<p>

<blockquote>
<a href=\"$url\">$link_title</a>- $link_description
</blockquote>

<p>

<form action=edit-3 method=post>
[export_form_vars page_id url_stub link_title link_description url contact_p old_url]
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_admin_footer]
"

doc_return  200 text/html $page_content