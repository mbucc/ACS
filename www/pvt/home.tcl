# /pvt/home.tcl
#
# user's workspace page
#
# written by lots of folks at lots of times and expected to change
#
# $Id: home.tcl,v 3.4.2.1 2000/04/28 15:11:23 carsten Exp $

set user_id [ad_verify_and_get_user_id]

# sync up the curriculum system if necessary 
if [ad_parameter EnabledP curriculum 0] {
    set new_cookie [curriculum_sync]
    if ![empty_string_p $new_cookie] {
	ns_set put [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=$new_cookie; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
    }
}

set db [ns_db gethandle]

# If there are requirements to fulfill.
if {[database_to_tcl_string $db "select user_fulfills_requirements_p($user_id) from dual"] == "f"} {
    ad_returnredirect "fulfill-requirements.tcl"
    return
}

# if this user is part of intranet employees, send 'em over!
if { [ad_parameter IntranetEnabledP intranet 0] == 1 } {
    if { [im_user_is_employee_p $db $user_id] } {
	ad_returnredirect /intranet/index.tcl
	return
    }	
    if { [im_user_is_customer_p $db $user_id] } {
	set portal_extension [ad_parameter PortalExtension portals .ptl]
	set group_name [ad_parameter CustomerPortalName intranet "Customer Portals"]
	regsub -all { } [string tolower $group_name] {-} group_name_in_link 
	ad_returnredirect "/portals/${group_name_in_link}-1$portal_extension"
	return
    }	
}

set selection [ns_db 0or1row $db "select 
  first_names, 
  last_name, 
  email, 
  url, 
  portrait_upload_date,
  portrait_client_file_name,
  nvl(screen_name,'&lt none set up &gt') as screen_name,
  bio
from users 
where user_id=$user_id"]

if [empty_string_p $selection] {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason.  You can visit <a href=\"/register/logout.tcl\">the log out page</a> and then start over."
    return
}

set_variables_after_query

if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
    set full_name "$first_names $last_name"
} else {
    set full_name "name unknown"
}

if [ad_parameter SolicitPortraitP "user-info" 0] {
    # we have portraits for some users 
    set portrait_chunk "<h4>Your Portrait</h4>\n"
    if { ![empty_string_p $portrait_upload_date] } {
	append portrait_chunk "On [util_AnsiDatetoPrettyDate $portrait_upload_date], you uploaded <a href=\"portrait/\">$portrait_client_file_name</a>."
    } else {
	append portrait_chunk "Show everyone else at [ad_system_name] how great looking you are:  <a href=\"portrait/upload.tcl\">upload a portrait</a>"
    }
} else {
    set portrait_chunk ""
}

# [ad_decorate_top "<h2>$full_name</h2>
# workspace at [ad_system_name]
# " [ad_parameter WorkspacePageDecoration pvt]]



set page_content "
[ad_header "$full_name's workspace at [ad_system_name]"]
<h2>$full_name's workspace at [ad_system_name]</h2>
[ad_context_bar [list / Home] "Your workspace"]

<hr>

<ul>
"


if { [ad_parameter IntranetEnabledP intranet 0] == 1 } {
    if { [im_user_is_authorized_p $db [ad_get_user_id]] } {
	append page_content "<li><a href=\"/shared/new-stuff.tcl\">new content</a> (site-wide)\n"
    }
}


append page_content "<p>\n"


set selection [ns_db select $db "
select section_id, section_url_stub, section_pretty_name, intro_blurb, help_blurb
from content_sections
where enabled_p = 't'
and scope='public'
order by sort_key, upper(section_pretty_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append content_section_items "<li><a href=\"$section_url_stub\">$section_pretty_name</a>\n"
    if ![empty_string_p $intro_blurb] {
	append content_section_items " - $intro_blurb"
    }
    if ![empty_string_p $help_blurb] {
	append content_section_items "[ad_space 2]<font size=-1><a href=\"content-help.tcl?[export_url_vars section_id]\">help</a></font>"
    }
    append content_section_items "<br>\n"
}

if [info exists content_section_items] {
    append page_content $content_section_items
}

set site_map [ad_parameter SiteMap content]

if ![empty_string_p $site_map] {
    append page_content "\n<p>\n<li><a href=\"$site_map\">site map</a>\n"
}

set selection [ns_db select $db "select ug.group_id, ug.group_name, ai.url as ai_url
from  user_groups ug, administration_info ai
where ug.group_id = ai.group_id
and ad_group_member_p ( $user_id, ug.group_id ) = 't'"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append admin_items "<li><a href=\"$ai_url\">$group_name</a>\n"
}

if [info exists admin_items] {
    append page_content "<p>

<li>You have the following administrative roles for this site:
<ul>
$admin_items
</ul>
<P>
"
}

set selection [ns_db select $db "select ug.group_id, ug.group_name, ug.short_name
from user_groups ug
where ug.group_type <> 'administration'
and ad_group_member_p ( $user_id, ug.group_id ) = 't'"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append group_items "<li><a href=\"[ug_url]/[ad_urlencode $short_name]/\">$group_name</a>\n"
}

if [info exists group_items] {
    append page_content "<p>

<li>You're a member of the following groups:
<ul>
$group_items
</ul>
<P>
"
}

# if { [ad_parameter IntranetEnabledP intranet 0] == 1 } {
#    # Right now only employees can see the intranet
#    # append page_content "    <li><a href=\"[ad_parameter IntranetUrlStub intranet "/intranet"]\">Intranet</a><p>\n"
#}

if { [ad_parameter StaffServerP "" 0] == 1 } {

    append page_content "
    <p>
    
    <li><a href=\"/file-storage/\">Documentation</a>

    <p>

    <li><a href=\"/ticket/\">Project and bug tracking</a>

    <P>

    <li><a href=\"/bboard/\">Discussion forums</a>

    <P>

"

}

set hp_html ""

if {[ad_parameter HomepageEnabledP users] == 1} {
    set hp_html "
    <h3>Homepages</h3>
    <ul>
    <li><a href=/homepage/index.tcl>Homepage Maintenance</a> - Maintain your personal homepage at [ad_parameter SystemName]
    <p>
    <li><a href=/homepage/neighborhoods.tcl>Neighborhoods</a> - Browse homepage neighborhoods at [ad_parameter SystemName]
    <p>
    <li><a href=/homepage/all.tcl>User Homepages</a> - List user homepages at [ad_parameter SystemName]
    </ul>
    "
}

append page_content "

<p>

<li><a href=\"/register/logout.tcl\">Log Out</a>

<p>

<li><a href=\"password-update.tcl\">Change my Password</a>


</ul>

$hp_html

<h3>What we tell other users about you</h3>

In general we identify content that you've posted by your full name.
In an attempt to protect you from unsolicited bulk email (spam), we
keep your email address hidden except from other registered users.
Total privacy is technically feasible but an important element of an
online community is that people can learn from each other.  So we try
to make it possible for users with common interests to contact each
other.

<p>

If you want to check what other users of this service are shown, visit
<a href=\"/shared/community-member.tcl?[export_url_vars user_id]\">[ad_url]/shared/community-member.tcl?[export_url_vars user_id]</a>.

<h4>Basic Information</h4>

<ul>
<li>Name:  $full_name
<li>email address:  $email 
<li>personal URL:  <a target=new_window href=\"$url\">$url</a>
<li>screen name:  $screen_name
<li>biography:  $bio
<p>
(<a href=\"basic-info-update.tcl\">update</a>)
</ul>

$portrait_chunk
"

set selection [ns_db select $db "select 
  c.category, 
  c.category_id, 
  decode(ui.category_id,NULL,NULL,'t') as selected_p
from categories c, (select * 
                    from users_interests 
                    where user_id = $user_id 
                    and interest_level > 0) ui
where c.enabled_p = 't' 
and c.category_id = ui.category_id(+)"]

set interest_items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $selected_p == "t" } {
	append interest_items "<input name=category_id type=checkbox value=\"$category_id\" CHECKED> $category<br>\n"
    } else {
	append interest_items "<input name=category_id type=checkbox value=\"$category_id\"> $category<br>\n"
    }
}

if ![empty_string_p $interest_items] {
    append page_content "
<h3>Your Interests (According to Us)</h3>

<form method=POST action=\"interests-update.tcl\">
<blockquote>
$interest_items
<br>
<br>
<input type=submit value=\"Update Interests\">
</blockquote>
</form>
"
}

append page_content "

<h3>If you're getting too much email from us</h3>

Then you should either 

<ul>
<li><a href=\"alerts.tcl\">edit your alerts</a>

<p>

or

<p>

<li><a href=\"unsubscribe.tcl\">Unsubscribe</a> (for a period of vacation or permanently)

</ul>



[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_content
