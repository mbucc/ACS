# /links/edit-2.tcl

ad_page_contract {
    Step 2 of 3 in editing a static page's link

    @param page_id The ID of the page to edit
    @param link_description The new description of the link
    @param link_title The new title of the link
    @param url The new URL
    @param contact_p Whether or not to contact about link status
    @param old_url The old URL
    @param submit Whether editing or deleting is taking place

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id edit-2.tcl,v 3.2.2.7 2000/09/22 01:38:52 kevin Exp
} {
    page_id:notnull,naturalnum
    link_description:notnull
    link_title:notnull
    url:notnull
    contact_p:notnull
    old_url:notnull
    submit:notnull
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

db_1row select_page_info "select  nvl(page_title,url_stub) as page_title, url_stub 
from static_pages
where page_id = :page_id"

# check for valid data

set exception_count 0
set exception_text ""

if { [string match $url "http://"] ==  1 } {
    # user left the default in instead of typing in a url
    incr exception_count
    append exception_text "<li> Please type in a URL."
}

if {![philg_url_valid_p $url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    append exception_text "<li>You URL doesn't have the correct form.  A valid URL would be something like \"http://photo.net/philg/\"."
}

if { [string length $link_description] > 4000 } {
    incr exception_count
    append exception_text "<li> Please limit your link description to 4000 characters."
}

set lower_url "[string tolower $url]"
if { [db_string select_url_exists "select count(url) from links where page_id = :page_id and lower(url)=:lower_url and user_id <> :user_id"] > 0  } {
    # another user has submitted this link
    incr exception_count
    append exception_text "<li> $url was already submitted by another user."
}

db_release_unused_handles

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# data is valid, move on

set page_content "[ad_header "Confirm link on <i>$page_title</i>" ]

<h2>Confirm link</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

The following is your link as it would appear on the page <i>$page_title</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Proceed\".
<p>
<blockquote>
<a href=\"$url\">$link_title</a>- $link_description
</blockquote>
<form action=edit-3 method=post>
[export_form_vars page_id url_stub link_title link_description url contact_p old_url]
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]
"

doc_return  200 text/html $page_content
