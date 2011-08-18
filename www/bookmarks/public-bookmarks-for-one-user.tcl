# $Id: public-bookmarks-for-one-user.tcl,v 3.0.4.2 2000/04/28 15:09:47 carsten Exp $
# public-bookmarks.tcl
#
# show other people's bookmarks
#
# by dh@arsdigita.com and aure@arsdigita.com
#
# fixed on November 7, 1999 by philg@mit.edu to release
# database handle and also call correct context bar

set_the_usual_form_variables 0

# viewed_user_id

set title "Show public bookmarks"

# get generic display parameters from the .ini file
set folder_bgcolor [ad_parameter FolderBGColor bm]
set bookmark_bgcolor [ad_parameter BookmarkBGColor bm]
set folder_decoration [ad_parameter FolderDecoration bm]
set dead_decoration [ad_parameter DeadDecoration bm]

set db [ns_db gethandle]

# Get the bookmarks' owner's name.
set name [database_to_tcl_string_or_null $db "select first_names || ' ' || last_name
from users
where user_id = $viewed_user_id"]

if { $name == "" } {
    ad_returnredirect public-bookmarks.tcl
    return
}

set title "$name's bookmarks"
set html "
[ad_header $title ]

<h2> $title </h2>

[ad_context_bar_ws_or_index [list "index.tcl" [ad_parameter SystemName bm]] [list "public-bookmarks.tcl" "Public Bookmarks"] "For one user"]


<hr>

[help_upper_right_menu [list "/shared/community-member.tcl?user_id=$viewed_user_id" "community member page for $name"]]
<br clear=all>
"

append bookmark_html "<table bgcolor=#f3f3f3 cellpadding=0 cellspacing=0 border=0 width=100%><tr><td width=100%><img border=0 src=pics/ftv2folderopen.gif align=top><b>$name's Bookmarks</b></td></tr></table>"

# get the bookmarks from the database and parse the output to reflect the folder stucture
# - in doing so determine if a given element (bookamrk/folder) is in a private folder.

set sql_query "
        select   bookmark_id, bm_list.url_id, folder_p,
                 nvl(local_title, url_title) as bookmark_title, complete_url, 
                 last_live_date, last_checked_date, length(parent_sort_key)*8 as indent_width 
        from     bm_list, bm_urls
        where    owner_id=$viewed_user_id
        and      bm_list.url_id=bm_urls.url_id(+)
        and      hidden_p='f'
        order by parent_sort_key || local_sort_key
        "

set selection [ns_db select $db $sql_query]

set bookmark_count 0
set bookmark_list ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    # decoration refers to color and font of the associated text
    set decoration ""

    # make dead links appear  as definied in the .ini file
    if {$last_checked_date!=$last_live_date} {
	append decoration $dead_decoration
    }
    
    # make folder titles appear  as definied in the .ini file
    if {$folder_p=="t"} {
	append decoration $folder_decoration
    } 

    # define url, background color, and image depending on whether we are display a bookmark or folder
    if {$folder_p=="f"} {
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
        <tr>
          <td valign=top><img src=\"pics/spacer.gif\" width=$indent_width height=1></td>
          <td>$link<img width=24 height=22 border=0 src=\"$image\" align=top></a></td>
          <td width=100%>$link$decoration[string trim $bookmark_title]</a></td>
        </tr>
      </table>"
    
    incr bookmark_count
}


append html "$bookmark_list [bm_footer]"

ns_db releasehandle $db 

# serve the page
ns_return 200 text/html $html 
