# $Id: index.tcl,v 3.1 2000/03/01 19:41:50 jsalz Exp $
# File:        index.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: If the user has not yet logged in, invites him/her to do so.
#              Gives the user the option to view presentations in different
#              ways.
# Inputs:      bulk_copy (if we're doing a bulk copy)
#              show_user, show_age

set_the_usual_form_variables 0
set user_id [ad_verify_and_get_user_id]

# Remember slider settings for this page, using the wp_index_sliders cookie.
set gen_slider_cookie 0
if { ![regexp {wp_index_sliders=([0-9a-z]*),([0-9a-z]*)} [ns_set get [ns_conn headers] Cookie] all old_show_user old_show_age] } {
    set old_show_user [expr { $user_id == 0 ? "all" : "" }]
    set old_show_age 14
}
if [info exists show_user] {
    set gen_slider_cookie 1
} else {
    set show_user $old_show_user
}
if [info exists show_age] {
    set gen_slider_cookie 1
} else {
    set show_age $old_show_age
}

if { $gen_slider_cookie } {
    set cookie "Set-Cookie: wp_index_sliders=$show_user,$show_age; Path=/\n";
} else {
    set cookie ""
}

if { [util_aolserver_2_p] } {
    set warning "<font color=red><b>Warning: WimpyPoint periodically crashes AOLserver 2 when viewing slides (every third page view or so).<br>Use this at your own risk!</b></font><p>"
} else {
    set warning ""
}

ns_write "HTTP/1.0 200 OK
Content-Type: text/html
$cookie
[wp_header_form "action=users.tcl" "WimpyPoint"]
[export_form_vars bulk_copy show_user show_age]

$warning

<table width=90%>
<tr>
<td>[wp_slider show_age $show_age { { 7 "Last Week" } { 14 "Last Two Weeks" } { 31 "Last Month" } { "" "All" } }]</td>
"

if { $show_age != "" } {
    set age_condition "and sysdate - wp.creation_date <= [wp_check_numeric $show_age]"
} else {
    set age_condition ""
}
if { $show_user == "all" || $user_id == 0 } {
    set user_condition ""
    set whose "Everyone's"
} else {
    set user_condition "and wp_access(presentation_id, $user_id, 'write', public_p, creation_user, group_id) is not null"
    set whose "Your"
}

set out ""
if { $user_id != 0 } {
    append out "<td align=right>[wp_slider show_user $show_user { { "" "Yours" } { "all" "Everyone's" } }]</td>\n"
}
append out "</tr>
</table>

<h3>$whose Presentations</h3>
<ul>
"

set db [ns_db gethandle]

wp_select $db "
    select u.last_name, u.first_names, u.email, presentation_id, title,
           creation_date, creation_user,
           wp_access(presentation_id, $user_id, 'read', public_p, creation_user, group_id) my_access
    from users u, wp_presentations wp
    where u.user_id = wp.creation_user $age_condition $user_condition
    order by wp.creation_date desc
" {
    if { $my_access == "" } {
	continue
    }

    
    if { [info exists bulk_copy] } {
	set main_href "bulk-copy-2.tcl?presentation_id=$bulk_copy&source_presentation_id=$presentation_id"
	set user_href "one-user.tcl?user_id=$creation_user&bulk_copy=$bulk_copy"
    } else {
	set main_href "[wp_presentation_url]/$presentation_id/"
	set user_href "/shared/community-member.tcl?user_id=$creation_user"
    }

    append out "<li><a href=\"$main_href\" target=_parent>[ns_striphtml $title]</a> created "
    if { $creation_user != $user_id } {
	append out "by <a href=\"$user_href\">$first_names $last_name</a> "
    }
    append out "on [util_IllustraDatetoPrettyDate $creation_date]"
    if { $my_access != "read" && ![info exists bulk_copy] } {
	append out " \[ <a href=\"presentation-top.tcl?presentation_id=$presentation_id\">edit</a> \]"
    }
    append out "\n"	
} else {
    if { $show_age == 7 } {
	set age_str " created in the last week"
    } elseif { $show_age == 14 } {
	set age_str " created in the last two weeks"
    } elseif { $show_age == 31 } {
	set age_str " created in the last month"
    } elseif { $show_age == "" } {
	set age_str ""
    } else {
	set age_str " created in the last $show_age days"
    }

    if { $show_user == "" } {
	append out "<li>You have no presentations$age_str.
<a href=\"presentation-edit.tcl\">Create a new presentation</a>.\n"
    } else {
	append out "<li>There are no presentations$age_str.\n"
    }
}


append out "</ul>
<h3>Options</h3>
<ul>\n"
if { [info exists bulk_copy] } {
    set bulk_copy_query "&bulk_copy=$bulk_copy"
} else {
    set bulk_copy_query ""
}

if { $user_id == 0 } {
    # If the user hasn't logged in, prompt him/her to do so.
    append out "<li>To create or edit presentations, please <a href=\"/register/?return_url=[ns_urlencode [ns_conn url]]\">log in</a>.\n"
} else {
    if { ![info exists bulk_copy] } {
	append out "<li><a href=\"presentation-edit.tcl\">Create a new presentation</a>."
    }
}
append out "
<li>Show a list of <a href=\"users.tcl?[export_ns_set_vars]\">all WimpyPoint users</a>.
<li>Show a list of WimpyPoint users with last names beginning with
<input name=starts_with size=5>. <input type=submit value=Go>
</form><form action=search.tcl>
<!--li>Search through all slides for: <input size=30 name=search> <input type=submit value=\"Search\"-->
"

if { $user_id != 0 && ![info exists bulk_copy] } {
    append out "<li>Edit one of <a href=\"style-list.tcl\">your styles</a>.\n"
}

append out "</ul>\n"

ns_write "$out

[wp_footer]

"

