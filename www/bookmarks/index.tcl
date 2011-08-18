# /bookmarks/index.tcl
#
# Front page to the bookmarks system
#
# by aure@arsdigita.com and dh@arsdigita.com, June 1999
#
# $Id: index.tcl,v 3.0.4.1 2000/03/15 04:54:31 aure Exp $

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set page_title [ad_parameter SystemName bm]

# get generic display parameters from the .ini file
set folder_bgcolor [ad_parameter FolderBGColor bm]
set bookmark_bgcolor [ad_parameter BookmarkBGColor bm]
set folder_decoration [ad_parameter FolderDecoration bm]
set hidden_decoration [ad_parameter HiddenDecoration bm]
set dead_decoration [ad_parameter DeadDecoration bm]

set edit_anchor "<font size=-2 face=\"verdana, arial, helvetica\">edit</font>"

# the javascript function that spawns the bookmark window
set javascript "
<script runat=client>
function launch_window(file) {
    window.open(file,'bookmarks','toolbar=no,location=no,directories=no,status=no,scrollbars=auto,resizable=yes,copyhistory=no,width=350,height=480')
}
</script>
"

# display header and list of user options 
set page_content "
[ad_header $page_title $javascript]

<h2> $page_title </h2>

[ad_context_bar_ws $page_title ]

<hr>
\[<a href=import?return_url=index>Add / Import</a> |
 <a href=export>Export</a> |
 <a href=create-folder?return_url=index>Create New Folder</a> |
 <a href=live-check?return_url=index>Check Links</a> |
 <a href=\"javascript:launch_window('tree')\">Javascript version</a> |
 <a href=public-bookmarks>View public bookmarks</a> \] <p>"

set name [database_to_tcl_string $db "select first_names || ' ' || last_name as name from users where user_id = $user_id"]

append page_content "
<table bgcolor=$folder_bgcolor cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
<td width=100%><img border=0 src=pics/ftv2folderopen.gif align=top>${folder_decoration}Bookmarks for $name</td>
<td><a href=toggle-open-close?action=close_all>Close</a>/<a href=toggle-open-close?action=open_all>Open</a> All Folders</td>    
</tr>
</table>"

set bookmark_query "
    select   bookmark_id, 
             bm_list.url_id, 
             nvl(local_title, url_title) as bookmark_title, 
             hidden_p, 
             complete_url,  
             last_live_date, 
             last_checked_date, 
             folder_p, 
             closed_p, 
             length(parent_sort_key)*8 as indent_width 
    from     bm_list, bm_urls
    where    owner_id = $user_id
    and      in_closed_p = 'f'
    and      bm_list.url_id = bm_urls.url_id(+)
    order by parent_sort_key || local_sort_key"

set selection [ns_db select $db $bookmark_query]

set bookmark_count 0
set bookmark_list ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    # decoration refers to color and font of the associated text
    set decoration ""

    # make private links appear as defined in the .ini file
    if {$hidden_p == "t"} {
	append decoration $hidden_decoration
    }

    # make dead links appear  as defined in the .ini file
    if {$last_checked_date != $last_live_date} {
	append decoration $dead_decoration
    }
    
    # make folder titles appear  as defined in the .ini file
    if {$folder_p == "t"} {
	append decoration $folder_decoration
    } 

    # dropping apostrophes and quotation marks from the javascript title
    # that will be used in the fancy edit link below
    regsub -all {'|"} $bookmark_title {} javascript_title

    # this fancy edit link shows "Edit foo" in the status bar
    set edit_link "<a onMouseOver=\"window.status='Edit $javascript_title'; return true;\" onMouseOut=\"window.status=' '; return true;\" href=edit-bookmark?return_url=index&[export_url_vars bookmark_id]>$edit_anchor</a>"


    # define url, background color, and image depending on whether we are display a bookmark or folder
    if {$folder_p == "f"} {
	set url $complete_url
	set bgcolor $bookmark_bgcolor
	set image "pics/ftv2doc.gif"
    } else {
	set bgcolor $folder_bgcolor
	set url "toggle-open-close?[export_url_vars bookmark_id]"

	# different images for whether or not the folder is open
	if {$closed_p == "t"} {
	    set image "pics/ftv2folderclosed.gif"
	} elseif {$closed_p == "f" } {
	    set image "pics/ftv2folderopen.gif"
	}
    }

    append bookmark_list "
    <table bgcolor=$bgcolor cellpadding=0 cellspacing=0 border=0 width=100%>
    <tr>
    <td valign=top><img src=\"pics/spacer.gif\" width=$indent_width height=1></td>
    <td><a href=\"$url\"><img width=24 height=22 border=0 src=\"$image\" align=top></a></td>
    <td width=100%><a href=\"$url\">$decoration[string trim $bookmark_title]</a></td>
    <td>$edit_link</td>
    </tr>
    </table>"
    
    incr bookmark_count
}

# write the bookmarks if there are any to show
if {$bookmark_count!=0} {
    append page_content "$bookmark_list"
} else {
    append page_content "You don't have any bookmarks stored in the database. <p>"
}

append page_content "<form action=search method=post>
 Search bookmarks for: <input name=search_text type=text size=20><input type=hidden name=return_url value=index><input type=submit value=Search></form>
<p>
Key to bookmark display:
<table>
<tr>
<td><ul><li> $hidden_decoration Private or hidden files or folders appear like this.</td>
</tr>
<tr>
<td><ul><li> $dead_decoration Unreachable links appear like this. These links may not be completely dead, but they were unreachable by our server on last attempt.</td>
</tr>
</table>"

# Add a footer
append page_content "[bm_footer]"

# release the database handle
ns_db releasehandle $db 

# serve the page
ns_return 200 text/html $page_content 
