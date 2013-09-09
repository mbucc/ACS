# /www/bookmarks/public-bookmarks-for-one-user.tcl

ad_page_contract {
    show other people's bookmarks

    @param viewed_user_id the ID of the user
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id public-bookmarks-for-one-user.tcl,v 3.2.6.9 2000/09/22 01:37:03 kevin Exp
} {
    viewed_user_id:integer
} 

set title "Show public bookmarks"

# Get generic display parameters from the .ini file

set folder_bgcolor    [ad_parameter FolderBGColor    bm]
set bookmark_bgcolor  [ad_parameter BookmarkBGColor  bm]
set folder_decoration [ad_parameter FolderDecoration bm]
set dead_decoration   [ad_parameter DeadDecoration   bm]

# Get the bookmarks' owner's name.

set name [db_string user_name "
select first_names || ' ' || last_name
from   users 
where  user_id = :viewed_user_id" -default "" ]

if [empty_string_p $name] {
    ad_returnredirect public-bookmarks
    return
}

set title "$name's bookmarks"

set page_content "
[ad_header $title ]

<h2> $title </h2>

[ad_context_bar_ws_or_index \
	[list "" [ad_parameter SystemName bm]] \
	[list "public-bookmarks" "Public Bookmarks"] \
	"For one user"]

<hr>

[help_upper_right_menu \
	[list "/shared/community-member?user_id=$viewed_user_id" "community member page for $name"]]

<br clear=all>
"

append bookmark_html "
<table bgcolor=#f3f3f3 cellpadding=0 cellspacing=0 border=0 width=100%>
<tr><td width=100%><img border=0 src=pics/ftv2folderopen.gif align=top><b>$name's Bookmarks</b></td></tr></table>"

# Get the bookmarks from the database and parse the output to reflect the folder stucture
# - in doing so determine if a given element (bookamrk/folder) is in a private folder.

set bookmark_list ""

db_foreach bookmark {
    select   bookmark_id, 
             bm_list.url_id, 
             folder_p,
             nvl(local_title, url_title) as bookmark_title, 
             complete_url, 
             last_live_date, 
             last_checked_date, 
             length(parent_sort_key)*8 as indent_width 
    from     bm_list, bm_urls
    where    owner_id       = :viewed_user_id
    and      bm_list.url_id = bm_urls.url_id(+)
    and      hidden_p='f'
    order by parent_sort_key || local_sort_key
} { 

    # decoration refers to color and font of the associated text
    set decoration ""

    # make dead links appear  as definied in the .ini file
    if [string compare $last_checked_date $last_live_date] {
	append decoration $dead_decoration
    }
    
    # make folder titles appear as definied in the .ini file
    if {$folder_p == "t"} {
	append decoration $folder_decoration
    } 

    # define url, background color, and image depending on whether we are display a bookmark or folder
    if {$folder_p == "f"} {
	set link "<a href=$complete_url>"
	set bgcolor $bookmark_bgcolor
	set image "pics/ftv2doc.gif"
    } else {
	set link ""
	set bgcolor $folder_bgcolor
	set image "pics/ftv2folderopen.gif"
    }

    append bookmark_list "
    <table bgcolor=$bgcolor cellpadding=0 cellspacing=0 border=0 width=100%>
    <tr><td valign=top><img src=pics/spacer.gif width=$indent_width height=1></td><td>$link<img width=24 height=22 border=0 src=$image align=top></a></td><td width=100%>$link$decoration[string trim $bookmark_title]</a></td></tr></table>"
}

append page_content "$bookmark_list [bm_footer]"

db_release_unused_handles 

# serve the page
doc_return  200 text/html $page_content 


