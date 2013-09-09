# /www/bookmarks/search.tcl

ad_page_contract {

    The "not very bright" search engine for the bookmarks system
    @param search_text the keywork to search for
    @param return_url URL for user to return to 
    @author Aurelius Prochazka (aure@arsdigita.com)
    @cvs-id search.tcl,v 3.2.2.5 2000/09/22 01:37:03 kevin Exp
} {
    {search_text}
    {return_url}
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if [empty_string_p $search_text] {
    ad_return_complaint 1 "<li>please enter a search string"
    return
}

if [regexp {^%+$} $search_text] {
    ad_return_complaint 1 "<li>please search for more than just a wildcard."
    return
}


set page_title "Search for  \"$search_text\""

set search_pattern "%[string toupper $search_text]%"

set html "
[ad_header  $page_title ]
<h2> $page_title </h2>
[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title ]
<hr>
"

# this select gets all your bookmarks that match the user's request

set bookmark_count 0
set bookmark_html ""

db_foreach bookmark_search_user {
    select   bookmark_id, 
             complete_url,
             nvl(local_title, url_title) as title, 
             meta_keywords, 
             meta_description
    from     bm_list, 
             bm_urls
    where    owner_id = :user_id 
    and      folder_p = 'f'
    and      bm_list.url_id = bm_urls.url_id 
    and     (    upper(local_title)      like :search_pattern
              or upper(url_title)        like :search_pattern
              or upper(complete_url)     like :search_pattern
              or upper(meta_keywords)    like :search_pattern
              or upper(meta_description) like :search_pattern)
    order by title
} {
    incr bookmark_count

    append bookmark_html "
    <a href=edit-bookmark?[export_url_vars bookmark_id]><img border=0 src=pics/ftv2doc.gif align=top></a><a target=target_frame href=\"$complete_url\">$title</a><br>" 

}

if {$bookmark_count > 0} {
    append html "Here are your bookmarks that match your search:
    <ul> $bookmark_html</ul>"
} else {
    append html  "<p>We couldn't find any matches among your bookmarks.<p>\n"
}

# thie query searches across other peoples not hidden bookmarks (for
# which hidden_p='f')

set bookmark_count 0
set bookmark_html ""

db_foreach bookmark_search_other {
    select   distinct complete_url,
             nvl(local_title, url_title) as title, 
             meta_keywords, 
             meta_description, 
             folder_p
    from     bm_list, 
             bm_urls
    where    owner_id <> :user_id
    and      private_p = 'f'
    and      hidden_p  = 'f'
    and      folder_p  = 'f' 
    and      bm_list.url_id = bm_urls.url_id 
    and     (   upper(local_title)      like :search_pattern
             or upper(url_title)        like :search_pattern
             or upper(complete_url)     like :search_pattern
             or upper(meta_keywords)    like :search_pattern
             or upper(meta_description) like :search_pattern)
    order by title
} {
    incr bookmark_count
    
    if {$folder_p == "f"} {
	regsub " " $complete_url "%20" complete_url
	append bookmark_html "<img border=0 src=pics/ftv2doc.gif align=top>
	<a target=target_frame href=\"$complete_url\">$title</a><br>" 
    } else {
	append bookmark_html "<img border=0 src=pics/ftv2folderopen.gif align=top> $title <br>" 
    }
}

db_release_unused_handles
 
if {$bookmark_count > 0} {
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

doc_return  200 text/html $html

