# /www/intranet/employees/admin/change-subordinates.tcl

ad_page_contract {
    Screen to quickly transfer subordinates to a new supervisor
    

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Sat May 20 21:18:28 2000
    @cvs-id change-subordinates.tcl,v 3.5.2.9 2000/09/22 01:38:32 kevin Exp
    @param from_user_id The user id of the supervisor
    @param return_url The url to return to after finished
} {
    from_user_id:naturalnum
    {return_url ""}
}



set the_query\
	"select u.user_id, u.last_name || ', ' || u.first_names as user_name
	   from users u, im_employee_info info
	  where u.user_id=info.user_id
	    and info.supervisor_id=:from_user_id
	  order by lower(user_name)"

set results ""
set passthrough_list [list from_user_id return_url]

db_foreach get_user_info_for_supervisor $the_query {
    lappend passthrough_list "id.$user_id"
    append results "  <li><input type=checkbox name=id.$user_id value=t> $user_name</a>\n"
}

if { [empty_string_p $results] } {
    ad_return_error "No subordinates" "User $from_user_id has no subordinates"
    return
}

set from_user_name [db_string getname \
	"select u.first_names || ' ' || u.last_name from users u where u.user_id=:from_user_id"]

db_release_unused_handles

set page_title "Transfer subordinates from $from_user_name"
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list view?user_id=$from_user_id "One employee"] "Transfer subordinates"]

set page_body "

[im_format_number 1]
Select the employees that you want to transfer to a new supervisor:

<form method=post action=/user-search>
[export_form_vars from_user_id return_url]
<input type=hidden name=limit_to_users_in_group_id value=\"[im_employee_group_id]\">
<input type=hidden name=passthrough value=\"[join $passthrough_list " "]\">
<input type=hidden name=target value=\"[im_url_stub]/employees/admin/change-subordinates-2.tcl\">
<ul>
$results
</ul>

[im_format_number 2]
Enter the email address of the new supervisor (this will start a search):
<br><dd><input type=text name=email size=30>
<p>
<center><input type=submit></center>
</form>

"

doc_return  200 text/html [im_return_template]