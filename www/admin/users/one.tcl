ad_page_contract {
    Display information about one user
    (makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl)
    @cvs-id one.tcl,v 3.5.2.3.2.7 2000/09/22 01:36:19 kevin Exp
    @author Philip Greenspun (philg@mit.edu)
    @author mobin (mobin@arsdigita.com)
    @creation-date October 31, 1999
} {
    user_id:integer,optional,notnull
    user_id_from_search:integer,optional,notnull
}

if [info exists user_id_from_search] {
    set user_id $user_id_from_search
}

if { ![info exists user_id] } {
    ad_return_complaint "<li>You must specify a valid user_id."
}

set result [db_0or1row users_info_query "
select u.first_names, u.last_name, u.email, u.registration_date, u.registration_ip,
  u.last_visit,   u.user_state,
  nvl(u.screen_name,'&lt none set up &gt') as screen_name,
  user_demographics_summary(u.user_id) as demographics_summary,
  gp.portrait_id, gp.portrait_upload_date, gp.portrait_client_file_name
from users u, general_portraits gp
where u.user_id = :user_id
and u.user_id = gp.on_what_id(+)
and 'USERS' = gp.on_which_table(+)
and 't' = gp.portrait_primary_p(+)"]

if { $result != 1 } {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was nuked?"
    return
}


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
<li>Name:  $first_names $last_name (<a href=\"basic-info-update?user_id=$user_id\">edit</a>)
<li>Email:  <a href=\"mailto:$email\">$email</a> 
(<a href=\"basic-info-update?user_id=$user_id\">edit</a>)
<li>Screen name:  $screen_name (<a href=\"basic-info-update?user_id=$user_id\">edit</a>)
<li>User ID:  $user_id
<li>Registration date:  [util_AnsiDatetoPrettyDate $registration_date] 
"

if { [info exists registration_ip] && ![empty_string_p $registration_ip] } {
    append whole_page "from <a href=\"/admin/host?ip=[ns_urlencode $registration_ip]\">$registration_ip</a>\n"
}

if { ![empty_string_p $last_visit] } {
    append whole_page "<li>Last visit: $last_visit\n"
}

if { ![empty_string_p $portrait_id] } {
    append whole_page "<li>Portrait:  <a href=\"portrait?user_id=$user_id\">$portrait_client_file_name</a>\n"
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

set contact_info [ad_user_contact_info $user_id "site_admin"]

if ![empty_string_p $contact_info] {
    append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
<ul>
<li><a href=contact-edit?[export_url_vars user_id]>Edit contact information</a>
</ul>"
} else {
    append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
<ul>
<li><a href=contact-edit?[export_url_vars user_id]>Add contact information</a>
</ul>"
}

db_with_handle db {
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
}

set category_items ""
db_foreach users_category_info "select c.category 
from categories c, users_interests ui 
where ui.user_id = :user_id
and c.category_id = ui.category_id" {
    append category_items "<LI>$category\n"
}

if ![empty_string_p $category_items] {
    append whole_page "<H3>Interests</H3>\n\n<ul>\n\n$category_items\n\n</ul>"
}

append whole_page [ad_summarize_user_contributions $user_id "site_admin"]

# randyg is brilliant! we can recycle the same handle here because the
# inner argument is evaluated before the outer one. this should actually
# be done with the db api. 12 june 00, richardl@arsdigita.com

if { [im_enabled_p] && [ad_user_group_member [im_employee_group_id] $user_id] } {
    # We are running an intranet enabled acs and this user is a member of the 
    # employees group. Offer a link to the employee administration page
    set intranet_admin_link "<li><a href=\"[im_url_stub]/employees/admin/view?[export_url_vars user_id]\">Update this user's employee information</a><p>"
} else {
    set intranet_admin_link ""
}

append whole_page "

<h3>Administrative Actions</h3>

<ul>
$intranet_admin_link
<li><a href=\"quota?user_id=$user_id\">Update this user's webspace quota</a><p>

<li><a href=\"password-update?user_id=$user_id\">Update this user's password</a><p>

<li><a href=\"portrait/index?[export_url_vars user_id]\">Manage this user's portrait</a><p>


<p>

<li><form method=POST action=search>
<input type=hidden name=u1 value=$user_id>
<input type=hidden name=target value=\"/admin/users/merge/merge-from-search.tcl\">
<input type=hidden name=passthrough value=\"u1\">
Search for an account to merge with this one: 
<input type=text name=keyword size=20>

</form>

<p>
<li><a href=\"nuke?user_id=$user_id\">Nuke this user</a> (only appropriate for test users)
<p>
<li><a href=\"become?user_id=$user_id\">Become this user!</a>
</ul>

[ad_admin_footer]
"

doc_return  200 text/html $whole_page
