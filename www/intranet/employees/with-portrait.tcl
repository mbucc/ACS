# $Id: with-portrait.tcl,v 3.4.2.1 2000/03/17 07:25:54 mbryzek Exp $
#
# File: /www/intranet/employees/with-portrait.tcl
#
# by philg@mit.edu on September 27, 1999
# 
# a registration-required page that shows the portraits 
# of all the users in the system who have uploaded them
#
# we have dimension controls on top to toggle "recent"|"all"
# and some kind of order-by control 
# and some kind of text list (with links), thumbnails, full-size
# control

ad_maybe_redirect_for_registration

set_the_usual_form_variables 0 

# optional text_picture_dim, recent_all_dim, order_by 

if { ![info exists text_picture_dim] || [empty_string_p $text_picture_dim] } {
    set text_picture_dim "links"
}

if { ![info exists recent_all_dim] || [empty_string_p $recent_all_dim] } {
    set recent_all_dim "recent"
}

switch $text_picture_dim {
    links  { set text_picture_bar "links | 
<a href=\"with-portrait.tcl?text_picture_dim=thumbnails&[export_ns_set_vars url text_picture_dim]\">thumbnails</a> |
<a href=\"with-portrait.tcl?text_picture_dim=full_size&[export_ns_set_vars url text_picture_dim]\">full-size</a>" }
    thumbnails  { set text_picture_bar "<a href=\"with-portrait.tcl?text_picture_dim=links&[export_ns_set_vars url text_picture_dim]\">links</a> |
thumbnails |
<a href=\"with-portrait.tcl?text_picture_dim=full_size&[export_ns_set_vars url text_picture_dim]\">full-size</a>" }
    full_size  { set text_picture_bar "<a href=\"with-portrait.tcl?text_picture_dim=links&[export_ns_set_vars url text_picture_dim]\">links</a> |
<a href=\"with-portrait.tcl?text_picture_dim=thumbnails&[export_ns_set_vars url text_picture_dim]\">thumbnails</a> |
full-size" }
}


set order_by_clause "order by upper(last_name), upper(first_names), upper(email)"
switch $recent_all_dim {
    recent { set recent_all_bar "recent |
<a href=\"with-portrait.tcl?recent_all_dim=all&[export_ns_set_vars url recent_all_dim]\">all</a>"
             set order_by_clause "order by portrait_upload_date desc" }
    all { set recent_all_bar "<a href=\"with-portrait.tcl?recent_all_dim=recent&[export_ns_set_vars url recent_all_dim]\">recent</a> | all" }
	     
}

set page_title "Employees with portraits"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list index.tcl Employees] "Employees with portraits"]

ReturnHeaders
ns_write "
[ad_partner_header]

<table width=100%>
<tr>
<td align=left>
$text_picture_bar
<td align=right>
$recent_all_bar
</table>

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "
    select 
        user_id, first_names, last_name, email, priv_email,
        portrait_upload_date, portrait_original_width, portrait_original_height, portrait_client_file_name,
        portrait_thumbnail_width, portrait_thumbnail_height
    from 
        users
    where 
        portrait_upload_date is not null and
        ad_group_member_p ( user_id, [im_employee_group_id] ) = 't'
    $order_by_clause"]


set rows ""
set count 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    if { $count > 50 && $recent_all_dim == "recent" } {
	# they only wanted to see the recent ones 
	ns_db flush $db
	break
    }
    append rows "\n<p><li> <a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a>"
    if { $priv_email <= [ad_privacy_threshold] } {
	append rows ", <a href=\"mailto:$email\">$email</a>"
    }
    # try to put the portrait in there
    if { $text_picture_dim == "links" } {
	append rows ", <a href=\"/shared/portrait.tcl?[export_url_vars user_id]\">$portrait_client_file_name</a>"
    } elseif { $text_picture_dim == "thumbnails" } {
	# **** this should really be smart and look for the actual thumbnail
	# but it isn't and just has the browser smash it down to a fixed width
	append rows "<br><dd><a href=\"/shared/portrait.tcl?[export_url_vars user_id]\"><img width=200 src=\"/shared/portrait-bits.tcl?[export_url_vars user_id]\"></a>\n"
    } else { 
	# must be the full thing
	if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
	    set widthheight "width=$portrait_original_width height=$portrait_original_height"
	} else {
	    set widthheight ""
	}
	append rows "<br><dd><a href=\"/shared/portrait.tcl?[export_url_vars user_id]\"><img $widthheight src=\"/shared/portrait-bits.tcl?[export_url_vars user_id]\"></a>"
    }
}

ns_db releasehandle $db 

ns_write "$rows
</ul>

[ad_partner_footer]
"
