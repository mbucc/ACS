# /www/directory/portrait-browse.tcl

ad_page_contract {

    a registration-required page that shows the portraits 
    of all the users in the system who have uploaded them
    
    we have dimension controls on top to toggle "recent"|"all"
    and some kind of order-by control 
    and some kind of text list (with links), thumbnails, full-size
    control

    @author Philip Greenspun (philg@mit.edu)
    @creation-date September 27, 1999
    @cvs-id portrait-browse.tcl,v 3.3.2.6 2000/12/20 23:18:00 kevin Exp
    @param text_picture_dim A size dimensional, whether we display "links", "thumbnails", or "full_size"
    @param recent_all_dim A recency dimensional, whether we order by name (all) or recency (recent)
} {
    {text_picture_dim "links"}
    {recent_all_dim "recent"}
    
}

ad_maybe_redirect_for_registration





switch $text_picture_dim {
    links  { set text_picture_bar "links | 
<a href=\"portrait-browse?text_picture_dim=thumbnails&[export_ns_set_vars url text_picture_dim]\">thumbnails</a> |
<a href=\"portrait-browse?text_picture_dim=full_size&[export_ns_set_vars url text_picture_dim]\">full-size</a>" }
    thumbnails  { set text_picture_bar "<a href=\"portrait-browse?text_picture_dim=links&[export_ns_set_vars url text_picture_dim]\">links</a> |
thumbnails |
<a href=\"portrait-browse?text_picture_dim=full_size&[export_ns_set_vars url text_picture_dim]\">full-size</a>" }
    full_size  { set text_picture_bar "<a href=\"portrait-browse?text_picture_dim=links&[export_ns_set_vars url text_picture_dim]\">links</a> |
<a href=\"portrait-browse?text_picture_dim=thumbnails&[export_ns_set_vars url text_picture_dim]\">thumbnails</a> |
full-size" }
}

switch $recent_all_dim {
    recent { set recent_all_bar "recent |
<a href=\"portrait-browse?recent_all_dim=all&[export_ns_set_vars url recent_all_dim]\">all</a>"
             set order_by_clause "order by portrait_upload_date desc" }
    all { set recent_all_bar "<a href=\"portrait-browse?recent_all_dim=recent&[export_ns_set_vars url recent_all_dim]\">recent</a> |
all" 
         set order_by_clause "order by upper(last_name), upper(first_names), upper(email)" }
}

set page_body "
[ad_header "[ad_system_name] Portrait Gallery"]

<h2>Portrait Gallery</h2>

[ad_context_bar_ws_or_index [list "index" "User Directory"] "Portrait Gallery"]

<hr>
"

set html "
<table width=100%>
<tr>
<td align=left>
$text_picture_bar
<td align=right>
$recent_all_bar
</table>

<blockquote>
<table>
<tr><th>Name<th>Email<th>Image</tr>

"





set rows ""
set count 0 
db_foreach select_pics "
select user_id, 
       first_names, 
       last_name, 
       email, 
       priv_email,
       portrait_upload_date, 
       portrait_original_width, 
       portrait_original_height, 
       portrait_client_file_name,
       portrait_thumbnail_width, 
       portrait_thumbnail_height
from   users u, general_portraits gp
where  portrait_upload_date is not null 
and    gp.on_what_id = u.user_id
and    gp.on_which_table = 'USERS'
$order_by_clause" {
    incr count
    if { $count > 50 && $recent_all_dim == "recent" } {
	# they only wanted to see the recent ones 
	#ns__db flush $ db
	#This break should cause an automatic flush
	break
    }
    append rows "<tr>
    <td valign=top>
    <a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a>
</td>
<td valign=top>
"
    if { $priv_email <= [ad_privacy_threshold] } {
	append rows "<a href=\"mailto:$email\">$email</a>"
    } else {
	# email address is not available
	append rows "N/A"
    }
    append rows "</td>"
    # try to put the portrait in there
    if { $text_picture_dim == "links" } {
	append rows "<td valign=top>
<a href=\"/shared/portrait?[export_url_vars user_id]\">$portrait_client_file_name</a>
</td>
"
    } elseif { $text_picture_dim == "thumbnails" } {
	# **** this should really be smart and look for the actual thumbnail
	# but it isn't and just has the browser smash it down to a fixed width
	append rows "<td valign=top>
<a href=\"/shared/portrait?[export_url_vars user_id]\"><img width=200 src=\"/shared/portrait-bits?[export_url_vars user_id]\"></a>
</td>
"
    } else { 
	# must be the full thing
	if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
	    set widthheight "width=$portrait_original_width height=$portrait_original_height"
	} else {
	    set widthheight ""
	}
	append rows "<td valign=top>
<a href=\"/shared/portrait?[export_url_vars user_id]\"><img $widthheight src=\"/shared/portrait-bits?[export_url_vars user_id]\"></a>
</td>
"
    }
    append rows "</tr>\n"
}

db_release_unused_handles 

if { $count == 0 } {
    set html "
    <blockquote>
    <li> There are currently no portraits in the database.
    </blockquote>"
} else {
    append html $rows </table> </blockquote>
}

append page_body "

$html

[ad_style_bodynote "Note: The only reason you are seeing this page at all is that you
are a logged-in authenticated user of [ad_system_name]; this
information is not available to tourists.  If you want to change 
or augment your own listing, visit [ad_pvt_home_link]."]

[ad_footer]
"

doc_return  200 text/html $page_body
