# /www/shared/community-member.tcl

ad_page_contract {
    shows User A what User B has contributed to the community
    
    March 9, 2000: 
    February 1, 2000: Added check so that if this is an IntranetEnabled acs,
    we only only authorized intranet users to view community members other
    than themselves
    March 1, 1999:  philg edited this to suppress display of links that weren't live
    September 26, 1999:  philg added display of user-uploaded portraits
    November 1, 1999: philg trashed 90% of the code and replaced it with
    a call to ad_summarize_user_contributions

    @param user_id defaults to currently logged in user if there is one

    @cvs-id community-member.tcl,v 3.9.2.6 2000/09/22 21:34:19 kevin Exp
} {
    { user_id:integer "" }
}

if { [empty_string_p $user_id] } {
    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# Don't know what to do! 
	ad_return_error "Missing user_id" "We need a user_id to display the community page"
	return
    }
}

if { ![db_0or1row user_information "select first_names, last_name, email, priv_email, 
url, banning_note, registration_date, user_state, bio
from users 
where user_id=:user_id"] } {
    ad_return_error "No user found" "There is no community member with the user_id of $user_id"
    ns_log Notice "Could not find user_id $user_id in community-member.tcl from [ns_conn peeraddr]"
    return
}

set portrait_p [db_0or1row portrait_info {
  select portrait_id,  portrait_upload_date, portrait_original_width, portrait_original_height, 
	 portrait_client_file_name, portrait_thumbnail_width, portrait_thumbnail_height
    from general_portraits
   where on_what_id = :user_id
     and upper(on_which_table) = 'USERS'
     and approved_p = 't'
     and portrait_primary_p = 't'
}]

if { $portrait_p} {
    # there is a portrait 
    if ![empty_string_p $portrait_thumbnail_width] {
	# there is a thumbnail version
	set inline_portrait_html "<a href=\"portrait?[export_url_vars user_id]\"><img src=\"portrait-thumbnail-bits?[export_url_vars portrait_id]\" align=right width=$portrait_thumbnail_width height=$portrait_thumbnail_height></a>"
    } else {
	# no thumbnail; let's see what we can do with the main image
	if { ![empty_string_p $portrait_original_width] && $portrait_original_width < 300 } {
	    # let's show it inline
	    set inline_portrait_html "<a href=\"portrait?[export_url_vars user_id]\"><img src=\"portrait-bits?[export_url_vars portrait_id]\" align=right width=$portrait_original_width height=$portrait_original_height></a>"
	} else {
	    set inline_portrait_html "<table width=100%><tr><td align=right>Portrait:  <a href=\"portrait?[export_url_vars user_id]\">$portrait_client_file_name</a></td></tr></table>"
	}
    }
} else {
    set inline_portrait_html ""
}

db_release_unused_handles

ad_return_top_of_page "[ad_header "$first_names $last_name"]

<h2>$first_names $last_name</h2> 

[ad_context_bar_ws_or_index "Community member"]

<hr>

$inline_portrait_html
A member of the [ad_system_name] community since [util_AnsiDatetoPrettyDate $registration_date]
"

set page_content ""

if { $user_state == "deleted" } {
    append page_content "<blockquote><font color=red>this user is deleted</font></blockquote>\n"
}
if { $user_state == "banned" } {
    append page_content "<blockquote><font color=red>this user is deleted and
banned from the community for the following reason:
\"$banning_note\"</font></blockquote>\n"
}

# Let's see if we can show all intranet-specific information
set show_intranet_info_p 1
if { [im_enabled_p] && [ad_parameter KeepSharedInfoPrivate intranet 0] } {
    set current_user_id [ad_get_user_id]
    if { $current_user_id != $user_id && ![im_user_is_authorized_p $current_user_id] } {
	set show_intranet_info_p 0
    }
}

if { $show_intranet_info_p } {
    append page_content [im_user_information $user_id]
} else {

    if { $priv_email <= [ad_privacy_threshold] } {
	append page_content "<ul>
<li>E-mail $first_names $last_name:
<A HREF=\"mailto:$email\">$email</a>"
        if ![empty_string_p $url] {
	    append page_content "<li>Personal home page:  <a href=\"$url\">$url</a>\n"
	}
	append page_content "</ul>\n"
    } else {
	if ![empty_string_p $url] {
	    # guy doesn't want his email address shown, but we can still put out 
	    # the home page
	    append page_content "<ul><li>Personal home page:  <a href=\"$url\">$url</a></ul>\n"
	}
    }
}

if { [ad_verify_and_get_user_id] == 0 } {
    append page_content "<blockquote>
If you were to <a href=\"/register/index?return_url=[ns_urlencode "/shared/community-member?user_id=$user_id"]\">log in</a>, you'd be able to get more information on your fellow community member.
</blockquote>
"
}

set the_moby_summary [ad_summarize_user_contributions $user_id "web_display"]

append page_content $the_moby_summary

# don't sign it with the publisher's email address!

append page_content "
[ad_footer]
"

db_release_unused_handles

ns_write $page_content