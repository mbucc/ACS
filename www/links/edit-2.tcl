# $Id: edit-2.tcl,v 3.0 2000/02/06 03:49:29 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# page_id, link_description, link_title, url, maybe contact_p, old_url, submit

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

set selection [ns_db 1row $db "select  nvl(page_title,url_stub) as page_title, url_stub 
from static_pages
where page_id = $page_id"]
set_variables_after_query

# check for valid data

set exception_count 0
set exception_text ""

if { [info exists url] && [string match $url "http://"] ==  1 } {
    # the user left the default hint for the url
    set url ""
    set QQurl ""
}

if { ![info exists url] || [empty_string_p $url]  } {
    incr exception_count
    append exception_text "<li> Please type in a URL."
}

if {[info exists url] && ![empty_string_p $url] && ![philg_url_valid_p $url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    append exception_text "<li>You URL doesn't have the correct form.  A valid URL would be something like \"http://photo.net/philg/\"."
}

if { ![info exists link_description] || [empty_string_p $link_description] } {
    incr exception_count
    append exception_text "<li> Please type in a description of your link."
}

if { [info exists link_description] && [string length $link_description] > 4000 } {
    incr exception_count
    append exception_text "<li> Please limit your link description to 4000 characters."
}

if { ![info exists link_title] || [empty_string_p $link_title] } {
    incr exception_count
    append exception_text "<li> Please type in a title for your linked page."
}


if { [database_to_tcl_string $db "select count(url) from links where page_id = $page_id and lower(url)='[string tolower $QQurl]' and user_id <> $user_id"] > 0  } {
    # another user has submitted this link
    incr exception_count
    append exception_text "<li> $url was already submitted by another user."
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# data is valid, move on


ns_return 200 text/html "[ad_header "Confirm link on <i>$page_title</i>" ]

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
<form action=edit-3.tcl method=post>
[export_form_vars page_id url_stub link_title link_description url contact_p old_url]
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]
"
