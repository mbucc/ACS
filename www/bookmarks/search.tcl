# $Id: search.tcl,v 3.0 2000/02/06 03:35:34 ron Exp $
# search.tcl
#
# the "not very bright" search engine for the bookmarks system
#
# by aure@arsdigita.com

set_the_usual_form_variables

# search_text, return_url

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if [empty_string_p $QQsearch_text] {
    ad_return_complaint 1 "<li>please enter a search string"
    return
}

if [regexp {^%+$} $QQsearch_text] {
    ad_return_complaint 1 "<li>please search for more than just a wildcard."
    return
}

set db [ns_db gethandle]

set page_title "Search for  \"$search_text\""

set search_pattern "'%[string toupper $QQsearch_text]%'"

set html "
[ad_header  $page_title ]
<h2> $page_title </h2>
[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title ]
<hr>
"

# this select gets all your bookmarks that match your request
set sql_query "
        select   bookmark_id, complete_url,
                 nvl(local_title, url_title) as title, meta_keywords, meta_description
        from     bm_list, bm_urls
        where    owner_id = $user_id 
        and      folder_p = 'f'
        and      bm_list.url_id=bm_urls.url_id 
        and      (upper(local_title) like $search_pattern
        or       upper(url_title) like $search_pattern
        or       upper(complete_url) like $search_pattern
        or       upper(meta_keywords) like $search_pattern
        or       upper(meta_description) like $search_pattern)
        order by title
        "

set selection [ns_db select $db $sql_query]
set bookmark_count 0
set bookmark_html ""

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    incr bookmark_count

    append bookmark_html "
    <a href=edit-bookmark.tcl?[export_url_vars bookmark_id]><img border=0 src=pics/ftv2doc.gif align=top></a><a target=target_frame href=\"$complete_url\">$title</a><br>" 

}

if {$bookmark_count!=0} {
    append html "Here are your bookmarks that match your search:
    <ul> $bookmark_html</ul>"
} else {
    append html  "<p>We couldn't find any matches among your bookmarks.<p>\n"
}


# thie query searches across other peoples not hidden bookmarks (for
# which hidden_p='f')

set sql_query "
        select   distinct complete_url,
                 nvl(local_title, url_title) as title, meta_keywords, meta_description, folder_p
        from     bm_list, bm_urls
        where    owner_id <> $user_id
        and      private_p = 'f'
        and      hidden_p='f'
        and      folder_p='f' 
        and      bm_list.url_id=bm_urls.url_id 
        and      (upper(local_title) like $search_pattern
        or       upper(url_title) like $search_pattern
        or       upper(complete_url) like $search_pattern
        or       upper(meta_keywords) like $search_pattern
        or       upper(meta_description) like $search_pattern)
        order by title
        "

set selection [ns_db select $db $sql_query]
set bookmark_count 0
set bookmark_html ""

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    incr bookmark_count

    if {$folder_p=="f"} {
	regsub " " $complete_url "%20" complete_url
	append bookmark_html "<img border=0 src=pics/ftv2doc.gif align=top>
	<a target=target_frame href=\"$complete_url\">$title</a><br>" 
    } else {
	append bookmark_html "<img border=0 src=pics/ftv2folderopen.gif align=top> $title <br>" 
}
 
}

if {$bookmark_count!=0} {
    append html "Here are other people's bookmarks that match your search:
    <ul> $bookmark_html</ul>"
} else {
    append html  "Your search returned zero matches in other bookmark lists."
}


append html "
</ul>
Done. <a href=$return_url>Click</a> to continue.
<p>

[bm_footer]" 

ns_db releasehandle $db

ns_return 200 text/html $html








