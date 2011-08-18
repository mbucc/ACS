#
# /www/education/subject/admin/users.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com
#
# this page allows the person to select a user to lead a class
#

ad_page_variables {
    {target_url class-add.tcl}
    {param_list ""}
    {browse_type ""}
}


set db [ns_db gethandle]

if {[string compare [string tolower $browse_type] select_instructor] == 0} {
    set header "Select an Instructor/Moderator for the Class"
    set nav_bar_value "Select Instructor"
    set footer ""
    
} else {
    set header "Users"
    set nav_bar_value "Site Wide Users"
    set footer "<br><li><a href=user-add.tcl>Add a User</a>"
}


set return_string "
[ad_header "Add a Class @ [ad_system_name]"]

<h2> $header</h2>

[ad_context_bar_ws [list "../" "Subjects"] [list "" "Subject Administration"] $nav_bar_value]

<hr>
<blockquote>
"

set threshhold 50


#see if there are more than $threshhold users
#if so, give search options
#if not, list all of the users

if {[database_to_tcl_string $db "select count(user_id) from users"] < $threshhold } {
    set selection [ns_db select $db "select users.user_id, 
                       first_names, 
                       last_name
                  from users
                 where user_id > 2
              order by last_name, first_names"]

    append return_string "<h3>Current Users</h3><ul>"

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append return_string "
	<li><a href=\"${target_url}?user_id=$user_id&$param_list\">$last_name, $first_names</a><br>\n"
    }

} else {
    set vars_to_pass [export_url_vars target_url browse_type param_list]
    append return_string "
    <ul>
    <li>Browse by last name : 
    <a href=user-list.tcl?begin=A&end=H&lastletter=G&type=lastname&$vars_to_pass>A - G</a> |
    <a href=user-list.tcl?begin=H&end=N&lastletter=M&type=lastname&$vars_to_pass>H - M</a> |
    <a href=user-list.tcl?begin=N&end=T&lastletter=S&type=lastname&$vars_to_pass>N - S</a> |
    <a href=user-list.tcl?begin=T&end=z&lastletter=Z&type=lastname&$vars_to_pass>T - Z</a> 

    <p>

    <li>Browse by email address : 
    <a href=user-list.tcl?begin=A&end=H&lastletter=G&type=email&$vars_to_pass>A - G</a> |
    <a href=user-list.tcl?begin=H&end=N&lastletter=M&type=email&$vars_to_pass>H - M</a> |
    <a href=user-list.tcl?begin=N&end=T&lastletter=S&type=email&$vars_to_pass>N - S</a> |
    <a href=user-list.tcl?begin=T&end=z&lastletter=Z&type=email&$vars_to_pass>T - Z</a> 

    <p>

    <li><a href=user-list.tcl?begin=A&end=z&lastletter=Z&type=all&$vars_to_pass>Browse All Users</a>

    <Br>

    <form method=get action=user-search.tcl>
     
    <li>Search through all registered [ad_system_name] users:
    <p>
    <table>
    [export_form_vars target_url param_list browse_type]
    <tr><td align=right>by Email Address</td>
    <td><input type=text maxlength=100 size=30 name=email><BR></td>
    </td>
    <tr><td align=right>by Last Name </td>
    <td><input type=text maxlength=100 size=30 name=last_name><BR></td>
    </tr>
    <tr>
    <td colspan=2>
    <center><input type=submit value=\"Search For a User\"></center>
    </td>
    </table>
    </form>
    "
}

append return_string "
$footer
</ul>
</blockquote>
   
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string







