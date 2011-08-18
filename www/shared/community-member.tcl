# $Id: community-member.tcl,v 3.5.2.1 2000/04/27 18:40:31 carsten Exp $
#
# /shared/community-member.tcl
#
# shows User A what User B has contributed to the community
#

# March 9, 2000: 
# February 1, 2000: Added check so that if this is an IntranetEnabled acs,
# we only only authrozied intranet users to view community members other
# than themselves
# March 1, 1999:  philg edited this to suppress display of links that weren't live
# September 26, 1999:  philg added display of user-uploaded portraits
# November 1, 1999: philg trashed 90% of the code and replaced it with
# a call to ad_summarize_user_contributions

ad_page_variables {
    {user_id}
}

if [empty_string_p $user_id] {
    ad_return_error "user_id missing" "Please specify a user ID."
    return
}

set db [ns_db gethandle]

if { [im_enabled_p] && [ad_parameter KeepSharedInfoPrivate intranet 0] } {
    set current_user_id [ad_get_user_id]
    if { $current_user_id != $user_id && ![im_user_is_authorized_p $db $current_user_id] } {
	im_restricted_access
    }
}

# displays the contibutions of this member to the community

set selection [ns_db 0or1row $db "select first_names, last_name, email, priv_email, 
url, banning_note, registration_date, user_state,
portrait_upload_date, portrait_original_width, portrait_original_height, portrait_client_file_name, bio,
portrait_thumbnail_width, portrait_thumbnail_height
from users 
where user_id=$user_id"]

if [empty_string_p $selection] {
    ad_return_error "No user found" "There is no community member with the user_id of $user_id"
    ns_log Notice "Could not find user_id $user_id in community-member.tcl from [ns_conn peeraddr]"
    return
} else {
    set_variables_after_query
}

if ![empty_string_p $portrait_upload_date] {
    # there is a portrait 
    if ![empty_string_p $portrait_thumbnail_width] {
	# there is a thumbnail version
	set inline_portrait_html "<a href=\"portrait.tcl?[export_url_vars user_id]\"><img src=\"portrait-thumbnail-bits.tcl?[export_url_vars user_id]\" align=right width=$portrait_thumbnail_width height=$portrait_thumbnail_height></a>"
    } else {
	# no thumbnail; let's see what we can do with the main image
	if { ![empty_string_p $portrait_original_width] && $portrait_original_width < 300 } {
	    # let's show it inline
	    set inline_portrait_html "<a href=\"portrait.tcl?[export_url_vars user_id]\"><img src=\"portrait-bits.tcl?[export_url_vars user_id]\" align=right width=$portrait_original_width height=$portrait_original_height></a>"
	} else {
	    set inline_portrait_html "<table width=100%><tr><td align=right>Portrait:  <a href=\"portrait.tcl?[export_url_vars user_id]\">$portrait_client_file_name</a></td></tr></table>"
	}
    }
} else {
    set inline_portrait_html ""
}

ad_return_top_of_page "[ad_header "$first_names $last_name"]

<h2>$first_names $last_name</h2> 

[ad_context_bar_ws_or_index "Community member"]

<hr>

$inline_portrait_html
A member of the [ad_system_name] community since [util_AnsiDatetoPrettyDate $registration_date]
"

if { $user_state == "deleted" } {
    ns_write "<blockquote><font color=red>this user is deleted</font></blockquote>\n"
}
if { $user_state == "banned" } {
    ns_write "<blockquote><font color=red>this user is deleted and
banned from the community for the following reason:
\"$banning_note\"</font></blockquote>\n"
}


if { [im_enabled_p] } {
    ns_write [im_user_information $db $user_id]
} else {

    if { $priv_email <= [ad_privacy_threshold] } {
	ns_write "<ul>
<li>E-mail $first_names $last_name:
<A HREF=\"mailto:$email\">$email</a>"
        if ![empty_string_p $url] {
	    ns_write "<li>Personal home page:  <a href=\"$url\">$url</a>\n"
	}
	ns_write "</ul>\n"
    } else {
	if ![empty_string_p $url] {
	    # guy doesn't want his email address shown, but we can still put out 
	    # the home page
	    ns_write "<ul><li>Personal home page:  <a href=\"$url\">$url</a></ul>\n"
	}
    }
}


if { [ad_verify_and_get_user_id] == 0 } {
    ns_write "<blockquote>
If you were to <a href=\"/register/index.tcl?return_url=[ns_urlencode "/shared/community-member.tcl?user_id=$user_id"]\">log in</a>, you'd be able to get more information on your fellow community member.
</blockquote>
"
}

set the_moby_summary [ad_summarize_user_contributions $db $user_id "web_display"]

ns_db releasehandle $db

ns_write $the_moby_summary

# don't sign it with the publisher's email address!

ns_write "
[ad_footer]
"
