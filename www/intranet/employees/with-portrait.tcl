# /www/intranet/employees/with-portrait.tcl

ad_page_contract {

    a registration-required page that shows the portraits of all the
    users in the system who have uploaded them we have dimension
    controls on top to toggle recent|all and some kind of order-by
    control and some kind of text list (with links), thumbnails,
    full-size control 

    @author philg@mit.edu on September 27, 1999 

    @param text_picture_dim dimensional control
    @param recent_all_dim  recent or all switch   
    @param order_by   used by ad_table for sorting

    @cvs-id with-portrait.tcl,v 3.10.2.8 2000/09/22 01:38:31 kevin Exp
} {
    text_picture_dim:optional
    recent_all_dim:optional
    {viewing_group_id 0}
    order_by:optional
    
}

if { ![info exists text_picture_dim] || [empty_string_p $text_picture_dim] } {
    set text_picture_dim "links"
}

if { ![info exists recent_all_dim] || [empty_string_p $recent_all_dim] } {
    set recent_all_dim "recent"
}

switch $text_picture_dim {
    links  { set text_picture_bar "links | 
<a href=\"with-portrait?text_picture_dim=thumbnails&[export_ns_set_vars url text_picture_dim]\">thumbnails</a> |
<a href=\"with-portrait?text_picture_dim=full_size&[export_ns_set_vars url text_picture_dim]\">full-size</a>" }
    thumbnails  { set text_picture_bar "<a href=\"with-portrait?text_picture_dim=links&[export_ns_set_vars url text_picture_dim]\">links</a> |
thumbnails |
<a href=\"with-portrait?text_picture_dim=full_size&[export_ns_set_vars url text_picture_dim]\">full-size</a>" }
    full_size  { set text_picture_bar "<a href=\"with-portrait?text_picture_dim=links&[export_ns_set_vars url text_picture_dim]\">links</a> |
<a href=\"with-portrait?text_picture_dim=thumbnails&[export_ns_set_vars url text_picture_dim]\">thumbnails</a> |
full-size" }
}

set order_by_clause "order by upper(last_name), upper(first_names), upper(email)"
switch $recent_all_dim {
    recent { set recent_all_bar "recent |
<a href=\"with-portrait?recent_all_dim=all&[export_ns_set_vars url recent_all_dim]\">all</a>"
             set order_by_clause "order by portrait_upload_date desc" }
    all { set recent_all_bar "<a href=\"with-portrait?recent_all_dim=recent&[export_ns_set_vars url recent_all_dim]\">recent</a> | all" }
	     
}

set page_title "Employees with portraits"
set context_bar [ad_context_bar_ws [list ./ Employees] "Employees with portraits"]


set office_list [list "0" "All"]
set office_group_id [im_office_group_id] 
set office_query "select group_id, group_name
                  from user_groups 
                  where parent_group_id = :office_group_id
                  order by group_name"

db_foreach office_select $office_query {
    lappend office_list $group_id $group_name
} 

set office_slider [im_slider viewing_group_id $office_list $viewing_group_id "start_idx group_id"]

if {$viewing_group_id==0} {
    set viewing_group_clause ""
} else {
    set viewing_group_clause "and ad_group_member_p ( user_id, $viewing_group_id ) = 't'"
}

set page_body "
<table width=100%>
<tr>
<td align=left>
$text_picture_bar
<td align=center>
$office_slider
<td align=right>
$recent_all_bar
</table>

<ul>
"

set thumbnail_display_sql "
    select 
        u.user_id, u.first_names, u.last_name, u.email, u.priv_email, p.portrait_id,
        p.portrait_upload_date, p.portrait_original_width, p.portrait_original_height, p.portrait_client_file_name,
        p.portrait_thumbnail_width, p.portrait_thumbnail_height
    from 
        users u, general_portraits p
    where 
	u.user_id = p.on_what_id
	and upper(p.on_which_table) = 'USERS'
        and p.portrait_upload_date is not null 
        and ad_group_member_p ( user_id, [im_employee_group_id] ) = 't'
    $viewing_group_clause
    $order_by_clause"

set rows ""
set count 0 
db_foreach thumbnail_display $thumbnail_display_sql {
    incr count
    if { $count > 50 && $recent_all_dim == "recent" } {
	# they only wanted to see the recent ones 
	break
    }
    append rows "\n<p><li> <a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a>"
    if { $priv_email <= [ad_privacy_threshold] } {
	append rows ", <a href=\"mailto:$email\">$email</a>"
    }
    # try to put the portrait in there
    if { $text_picture_dim == "links" } {
	append rows ", <a href=\"/shared/portrait?[export_url_vars user_id]\">$portrait_client_file_name</a>"
    } elseif { $text_picture_dim == "thumbnails" } {
	# **** this should really be smart and look for the actual thumbnail
	# but it isn't and just has the browser smash it down to a fixed width
	append rows "<br><dd><a href=\"/shared/portrait?[export_url_vars user_id]\"><img width=200 src=\"/shared/portrait-bits?[export_url_vars portrait_id]\"></a>\n"
    } else { 
	# must be the full thing
	if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
	    set widthheight "width=$portrait_original_width height=$portrait_original_height"
	} else {
	    set widthheight ""
	}
	append rows "<br><dd><a href=\"/shared/portrait?[export_url_vars user_id]\"><img $widthheight src=\"/shared/portrait-bits?[export_url_vars portrait_id]\"></a>"
    }
}

append page_body "$rows
</ul>
"

doc_return  200 text/html [im_return_template]
