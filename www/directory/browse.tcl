# $Id: browse.tcl,v 3.1.2.1 2000/04/28 15:09:55 carsten Exp $
# modified 3/10/00 by flattop@arsdigita.com
# cleaned up the code


set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode "/directory/"]"
    return
}

set where_clauses [list "priv_name <= [ad_privacy_threshold]"]

if [ad_parameter UserBrowsePageLimitedToNotNullUrlP directory 1] {
    lappend where_clauses "url is not null"
    set list_headline "Your fellow users (only those who've given us personal homepage addresses):"
} else {
    set list_headline "Your fellow users:"
}

set simple_page_headline "<h2>Users</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "User Directory"] "Browse"]
"

if ![empty_string_p [ad_parameter BrowsePageDecoration directory]] {
    set page_headline "<table cellspacing=10><tr><td>[ad_parameter BrowsePageDecoration directory]<td>$simple_page_headline</tr></table>"
} else {
    set page_headline $simple_page_headline
}

ReturnHeaders

ns_write "
[ad_header "[ad_system_name] Users"]

$page_headline

<hr>

$list_headline

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select user_id, first_names, last_name, email, priv_email, url
from users
where [join $where_clauses " and "]
order by upper(last_name), upper(first_names), upper(email)"]


set list_items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append list_items "<li><a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a>"
    if { $priv_email <= [ad_privacy_threshold] } {
	append list_items " (<a href=\"mailto:$email\">$email</a>)"
    }
    if ![empty_string_p $url] {
	append list_items ":  <a href=\"$url\">$url</a>"
    }
    append list_items "\n"
}

ns_db releasehandle $db 

ns_write "$list_items
</ul>


[ad_style_bodynote "Note: The only reason you are seeing this page at all is that you
are a logged-in authenticated user of [ad_system_name]; this
information is not available to tourists.  If you want to change 
or augment your own listing, visit [ad_pvt_home_link]."]

[ad_footer]
"
