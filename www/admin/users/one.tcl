# $Id: one.tcl,v 3.1 2000/03/09 00:01:35 scott Exp $
#
# /admin/users/one.tcl
#
# rewritten by philg@mit.edu on October 31, 1999
# makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl
#
# modified by mobin January 27, 2000 5:08 am

set_the_usual_form_variables

# user_id, maybe user_id_from_search

if [info exists user_id_from_search] {
    set user_id $user_id_from_search
}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select users.*,
nvl(screen_name,'&lt none set up &gt') as screen_name,
user_demographics_summary(user_id) as demographics_summary 
from users where user_id = $user_id"]

if [empty_string_p $selection] {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was nuked?"
    return
}

set_variables_after_query

append whole_page "[ad_admin_header "$first_names $last_name"]

<h2>$first_names $last_name</h2>

"

if ![empty_string_p $demographics_summary] {
    append whole_page "$demographics_summary"
}

append whole_page "<p>

[ad_admin_context_bar [list "index.tcl" "Users"] "One User"]


<hr>

"

append whole_page "

<ul>
<li>Name:  $first_names $last_name (<a href=\"basic-info-update.tcl?user_id=$user_id\">edit</a>)
<li>Email:  <a href=\"mailto:$email\">$email</a> 
(<a href=\"basic-info-update.tcl?user_id=$user_id\">edit</a>)
<li>Screen name:  $screen_name (<a href=\"basic-info-update.tcl?user_id=$user_id\">edit</a>)
<li>User ID:  $user_id
<li>Registration date:  [util_AnsiDatetoPrettyDate $registration_date] 
"

if { [info exists registration_ip] && ![empty_string_p $registration_ip] } {
    append whole_page "from <a href=\"/admin/host.tcl?ip=[ns_urlencode $registration_ip]\">$registration_ip</a>\n"
}

if { ![empty_string_p $last_visit] } {
    append whole_page "<li>Last visit: $last_visit\n"
}

if { ![empty_string_p $portrait_upload_date] } {
    append whole_page "<li>Portrait:  <a href=\"portrait.tcl?user_id=$user_id\">$portrait_client_file_name</a>\n"
}


append whole_page "
<li> User state: $user_state"

set user_finite_state_links  [ad_registration_finite_state_machine_admin_links $user_state $user_id]

append whole_page "
 ([join $user_finite_state_links " | "])
</ul>"

# it looks like we should be doing 0or1row but actually
# we might be in an ACS installation where users_demographics
# isn't used at all

set contact_info [ad_user_contact_info $db $user_id "site_admin"]

if ![empty_string_p $contact_info] {
    append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
<ul>
<li><a href=contact-edit.tcl?[export_url_vars user_id]>Edit contact information</a>
</ul>"
} else {
    append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
<ul>
<li><a href=contact-edit.tcl?[export_url_vars user_id]>Add contact information</a>
</ul>"
}


if ![catch { set selection [ns_db 1row $db "select 
  ud.*,
  u.first_names as referring_user_first_names,
  u.last_name as referring_user_last_name
from users_demographics ud, users u
where ud.user_id = $user_id
and ud.referred_by = u.user_id(+)"] } ] {
    # the table exists and there is a row for this user
    set demographic_items ""
    for {set i 0} {$i<[ns_set size $selection]} {incr i} {
	set varname [ns_set key $selection $i]
	set varvalue [ns_set value $selection $i]
	if { $varname != "user_id" && ![empty_string_p $varvalue] } {
	    append demographic_items "<li>$varname: $varvalue\n"
	}
    }
    if ![empty_string_p $demographic_items] {
	append whole_page "<h3>Demographics</h3>\n\n<ul>$demographic_items</ul>\n"

    }
}



if ![catch { set selection [ns_db select $db "select c.category 
from categories c, users_interests ui 
where ui.user_id = $user_id
and c.category_id = ui.category_id"] } ] {
    # tables exist 
    set category_items ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append category_items "<LI>$category\n"
    }
    if ![empty_string_p $category_items] {
	append whole_page "<H3>Interests</H3>\n\n<ul>\n\n$category_items\n\n</ul>"
    }
}

append whole_page [ad_summarize_user_contributions $db $user_id "site_admin"]

append whole_page "

<h3>Administrative Actions</h3>

<ul>
<li><a href=\"quota.tcl?user_id=$user_id\">Update this user's webspace quota</a><p>

<li><a href=\"password-update.tcl?user_id=$user_id\">Update this user's password</a><p>

<p>

<li><form method=POST action=search.tcl>
<input type=hidden name=u1 value=$user_id>
<input type=hidden name=target value=\"/admin/users/merge/merge-from-search.tcl\">
<input type=hidden name=passthrough value=\"u1\">
Search for an account to merge with this one: 
<input type=text name=keyword size=20>

</form>


<p>
<li><a href=\"nuke.tcl?user_id=$user_id\">Nuke this user</a> (only appropriate for test users)
<p>
<li><a href=\"become.tcl?user_id=$user_id\">Become this user!</a>
</ul>

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
