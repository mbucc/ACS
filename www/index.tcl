ad_page_contract {

    Arsdigita Community System

    @cvs-id index.tcl,v 3.8.2.10 2000/09/22 01:34:07 kevin Exp
}

set special_index_page [ad_parameter SpecialIndexPage content]

if ![empty_string_p $special_index_page] {
    set full_filename "[ns_info pageroot]$special_index_page"
    if [file exists $full_filename] {
	if { [file extension $full_filename] == ".adp" } {
	    doc_return  200 text/html [ns_adp_parse -file $full_filename]
	} else {
	    ad_returnfile 200 text/html $full_filename
	}
	ad_returnredirect  $special_index_page
	return
    }
}

# publisher didn't have any special directive for the top-level
# page, so let's generate something

set old_login_process [ad_parameter "SeparateEmailPasswordPagesP" "" "0"]

set page_content "
[ad_header [ad_system_name]]

<h2>[ad_system_name]</h2>

<hr>

<h3>Login</h3>

<form method=post action=register/user-login>
[export_form_vars return_url]
<table>
<tr><td>Your email address:</td><td><INPUT type=text name=email></tr>
"

if { !$old_login_process } {
    append page_content "
    <tr><td>Your password:</td><td><input type=password name=password></td></tr>\n"

    if [ad_parameter AllowPersistentLoginP "" 1] {
	if [ad_parameter PersistentLoginDefaultP "" 1] {
	    set checked_option "CHECKED" 
	} else {
	    set checked_option "" 
	}

	append page_content "
	<tr><td colspan=2><input type=checkbox name=persistent_cookie_p value=t $checked_option> 
	Remember this address and password?
	(<a href=\"register/explain-persistent-cookies\">help</a>)</td></tr>\n"
    }
}

append page_content "
<tr><td></td><td><input type=submit value=Submit></td></tr>
</table>

</form>
"

set user_id [ad_get_user_id]

if { $user_id != 0 } {
    # they've got a cookie
    if ![catch { set user_name [db_string index_get_user_first_names {
	select first_names || ' ' || last_name as name 
	from users 
	where user_id = :user_id and 
	user_state <> 'deleted'
    }] } errmsg] {
	# no errors
	append page_content "
	If you like, you can go directly to <a href=\"[ad_pvt_home]\">$user_name's [ad_pvt_home_name] in [ad_system_name]</a>."
    }
    set requires_registration_p_clause ""
} else {
    # not logged in 
    set requires_registration_p_clause "and requires_registration_p <> 't'"
}

append page_content "<ul>"

db_foreach index_sections_display "
    select section_url_stub, 
           section_pretty_name
    from   content_sections
    where  scope='public' 
    and    enabled_p = 't' 
    $requires_registration_p_clause
    order by sort_key, upper(section_pretty_name)
" {
    append page_content "<li><a href=\"$section_url_stub\">$section_pretty_name</a>\n"
}

append page_content "
</ul>

[ad_footer]
"

doc_return  200 text/html $page_content
