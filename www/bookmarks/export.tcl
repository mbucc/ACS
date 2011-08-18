# $Id: export.tcl,v 3.0.4.2 2000/04/28 15:09:46 carsten Exp $
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]]"
    return
}


set title "Export Bookmarks"

set html "[ad_header "$title"]

<h2>$title</h2>

[ad_context_bar_ws "index.tcl [ad_parameter SystemName bm]" "$title"]

<hr>

<h3>Export bookmarks to Netscape-style bookmark.htm file</h3>

Clicking on the link below will deliver your bookmarks file in a
traditional Netscape format... that page choose File...Save As and
then save the file as 

C:\\Program Files\\Netscape\\Users\\<i>your_name</i>\\bookmark.htm


<blockquote>

 <a href=\"bookmark.htm\">bookmark.htm</a>
</blockquote>

<i>(Alternatively, you may right click on the above link 
and choose \"Save Target As...\" or \"Save Link As...\")</i>

[bm_footer]

"

ns_return 200 text/html $html

