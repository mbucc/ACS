# ACS 3.2 (MIT rules!)
# $Id: index.tcl,v 3.1.4.4 2000/04/28 15:08:21 carsten Exp $

set special_index_page [ad_parameter SpecialIndexPage content]


if ![empty_string_p $special_index_page] {
    set full_filename "[ns_info pageroot]$special_index_page"
    if [file exists $full_filename] {
#	ad_returnredirect  $special_index_page
#	return
    }
}

# publisher didn't have any special directive for the top-level
# page, so let's generate something

set old_login_process [ad_parameter "SeparateEmailPasswordPagesP" "" "0"]

ReturnHeaders 

ns_write "[ad_header [ad_system_name]]

<h2>[ad_system_name]</h2>

<hr>

<h3>Login</h3>

<FORM method=post action=\"register/user-login.tcl\">
[export_form_vars return_url]
<table>
<tr><td>Your email address:</td><td><INPUT type=text name=email></tr>
"

if { !$old_login_process } {
    ns_write "<tr><td>Your password:</td><td><input type=password name=password></td></tr>\n"
    if [ad_parameter AllowPersistentLoginP "" 1] {
	if [ad_parameter PersistentLoginDefaultP "" 1] {
	    set checked_option "CHECKED" 
	} else {
	    set checked_option "" 
	}
	ns_write "<tr><td colspan=2><input type=checkbox name=persistent_cookie_p value=t $checked_option> 
	Remember this address and password?
	(<a href=\"register/explain-persistent-cookies.adp\">help</a>)</td></tr>\n"
    }
}

ns_write "

<tr><td colspan=2 align=center><INPUT TYPE=submit value=\"Submit\"></td></tr>
</table>

</FORM>

"

set user_id [ad_get_user_id]
set db [ns_db gethandle]

if { $user_id != 0 } {
    # they've got a cookie
    if ![catch { set user_name [database_to_tcl_string $db "select first_names || ' ' || last_name as name from users where user_id = $user_id and user_state <> 'deleted'"] } errmsg] {
	# no errors
	ns_write "If you like, you can go directly to <a href=\"[ad_pvt_home]\">$user_name's [ad_pvt_home_name] in [ad_system_name]</a>."
    }
    set requires_registration_p_clause ""
} else {
    # not logged in 
    set requires_registration_p_clause "\nand requires_registration_p <> 't'"
}

ns_write "<ul>"

set selection [ns_db select $db "
select section_url_stub, section_pretty_name
from content_sections
where scope='public' and enabled_p = 't' $requires_registration_p_clause
order by sort_key, upper(section_pretty_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"$section_url_stub\">$section_pretty_name</a>\n"
}

ns_write "
</ul>

[ad_footer]
"
