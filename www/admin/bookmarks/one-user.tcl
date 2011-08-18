# /admin/bookmarks/one-user.tcl
#
# allows administration of a given users (owner_id) bookmarks
#
# by aure@arsdigita.com and dh@arsdigita.com, June 1999
#
# $Id: one-user.tcl,v 3.0.4.1 2000/03/15 21:11:38 aure Exp $

ad_page_variables {owner_id}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


# get database handle
set db [ns_db gethandle]

# get the bookmark owner's name
set owner_name [database_to_tcl_string $db "select first_names||' '||last_name from users where user_id = $owner_id"]

set title "$owner_name's Bookmarks"


# get generic display parameters from the .ini file
set folder_bgcolor    [ad_parameter FolderBGColor    bm]
set bookmark_bgcolor  [ad_parameter BookmarkBGColor  bm]
set folder_decoration [ad_parameter FolderDecoration bm]
set hidden_decoration [ad_parameter HiddenDecoration bm]
set dead_decoration   [ad_parameter DeadDecoration   bm]

set edit_anchor "<font size=-2 face=\"verdana, arial, helvetica\">edit</font>"

# --create the page ---------------------------
set page_content "
[ad_admin_header $title ]

<h2> $title </h2>
[ad_admin_context_bar  [list "" "Bookmarks"] $title]


<hr>

  <table bgcolor=$folder_bgcolor cellpadding=0 cellspacing=0 border=0 width=100%>
    <tr>
<td width=100%><img border=0 src=/bookmarks/pics/ftv2folderopen.gif align=top>${folder_decoration}Bookmarks for $owner_name</td>
    </tr>
  </table>"


set bookmark_query "
        select   bookmark_id, bm_list.url_id, 
                 nvl(local_title, url_title) as bookmark_title, 
                 hidden_p, complete_url,  
                 last_live_date, last_checked_date, 
                 folder_p, closed_p, length(parent_sort_key)*8 as indent_width  
        from     bm_list, bm_urls
        where    owner_id=$owner_id
        and      in_closed_p='f'
        and      bm_list.url_id=bm_urls.url_id(+)
        order by parent_sort_key || local_sort_key
        "

set selection [ns_db select $db $bookmark_query]

set bookmark_count 0
set bookmark_list ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    # decoration refers to color and font of the associated text
    set decoration ""

    # make private links appear as definied in the .ini file
    if {$hidden_p == "t"} {
	append decoration $hidden_decoration
    }

    # make dead links appear  as definied in the .ini file
    if {$last_checked_date != $last_live_date} {
	append decoration $dead_decoration
    }
    
    # make folder titles appear  as definied in the .ini file
    if {$folder_p == "t"} {
	append decoration $folder_decoration
    } 

    # dropping apostrophes and quotation marks from the javascript title
    # that will be used in the fancy edit link below
    regsub -all {'|"} $bookmark_title {} javascript_title

    # this fancy edit link shows "Edit foo" in the status bar
    set edit_link "<a onMouseOver=\"window.status='Edit $javascript_title'; return true;\" onMouseOut=\"window.status=' '; return true;\" href=edit-bookmark?return_url=one-user&[export_url_vars bookmark_id]>$edit_anchor</a>"


    # define url, background color, and image depending on whether we are display a bookmark or folder
    if {$folder_p=="f"} {
	set url $complete_url
	set bgcolor $bookmark_bgcolor
	set image "/bookmarks/pics/ftv2doc.gif"
    } else {
	set bgcolor $folder_bgcolor
	set url "toggle-open-close?[export_url_vars bookmark_id]"

	# different images for whether or not the folder is open
	if {$closed_p=="t"} {
	    set image "/bookmarks/pics/ftv2folderclosed.gif"
	} elseif {$closed_p=="f" } {
	    set image "/bookmarks/pics/ftv2folderopen.gif"
	}
    }

    append bookmark_list "
      <table bgcolor=$bgcolor cellpadding=0 cellspacing=0 border=0 width=100%>
        <tr>
          <td valign=top><img src=\"/bookmarks/pics/spacer.gif\" width=$indent_width height=1></td>
          <td><a href=\"$url\"><img width=24 height=22 border=0 src=\"$image\" align=top></a></td>
          <td width=100%><a href=\"$url\">$decoration[string trim $bookmark_title]</a></td>
          <td>$edit_link</td>
        </tr>
      </table>"
    
    incr bookmark_count
}

# write the bookmarks if there are any to show
if {$bookmark_count!=0} {
    append page_content $bookmark_list
} else {
    append page_content "No bookmarks stored in the database. <p>"
}


# Add a footer
append page_content "[ad_admin_footer]"

# release the database handle before serving the page
ns_db releasehandle $db 

# serve the page
ns_return 200 text/html $page_content 



