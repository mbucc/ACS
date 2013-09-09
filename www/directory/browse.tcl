# /www/directory/browse.tcl

ad_page_contract {
    browse the users

    @cvs-id browse.tcl,v 3.6.2.5 2000/09/22 01:37:20 kevin Exp
    @author unknown
} {}

set user_id [ad_maybe_redirect_for_registration]

set where_clauses [list "priv_name <= [ad_privacy_threshold]" "user_state = 'authorized'"]

if [ad_parameter UserBrowsePageLimitedToNotNullUrlP directory 1] {
    lappend where_clauses "url is not null"
    set list_headline "Your fellow users (only those who've given us personal homepage addresses):"
} else {
    set list_headline "Your fellow users:"
}

set simple_page_headline "<h2>Users</h2>

[ad_context_bar_ws_or_index [list "index" "User Directory"] "Browse"]
"

if ![empty_string_p [ad_parameter BrowsePageDecoration directory]] {
    set page_headline "<table cellspacing=10><tr><td>[ad_parameter BrowsePageDecoration directory]<td>$simple_page_headline</tr></table>"
} else {
    set page_headline $simple_page_headline
}


set body "
[ad_header "[ad_system_name] Users"]

$page_headline

<hr>

$list_headline

<ul>

"


set list_items ""

db_foreach browse_users "select user_id, first_names, last_name, email, priv_email, url
from users
where [join $where_clauses " and "]
order by upper(last_name), upper(first_names), upper(email)" {
    
    append list_items "<li><a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a>"
    if { $priv_email <= [ad_privacy_threshold] } {
	append list_items " (<a href=\"mailto:$email\">$email</a>)"
    }
    if ![empty_string_p $url] {
	append list_items ":  <a href=\"$url\">$url</a>"
    }
    append list_items "\n"
}

db_release_unused_handles 

append body "$list_items
</ul>

[ad_style_bodynote "Note: The only reason you are seeing this page at all is that you
are a logged-in authenticated user of [ad_system_name]; this
information is not available to tourists.  If you want to change 
or augment your own listing, visit [ad_pvt_home_link]."]

[ad_footer]
"

doc_return  200 text/html $body
