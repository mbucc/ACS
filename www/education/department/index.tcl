#
# /www/education/department/index.tcl
# 
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page lists the departments.  It still needs a lot of work.
#


set db [ns_db gethandle]

set return_string "

[ad_header "[ad_system_name] Administration"]

<h2>[ad_system_name] Departments</h2>

[ad_context_bar_ws Departments]

<hr>
<blockquote>

<h3>Departments</h3>
<ul>
"

# if they are a site wide admin we want to give them all possible links

set user_id [ad_verify_and_get_user_id]

set site_wide_admin_p [ad_administrator_p $db]

set count 0

# do use an on-the-fly view so that we know if the user is a member
# of the given deparment

set selection [ns_db select $db "select department_id, 
                     department_name, 
                     count(admin_list.group_id) as department_admin_p
                from edu_departments dept,
                     (select group_id 
                             from user_group_map 
                            where user_id = $user_id) admin_list
               where dept.department_id = admin_list.group_id(+)
            group by department_id, 
                     department_name"]



while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append return_string "<li><a href=\"one.tcl?department_id=$department_id\">$department_name</a>"

    if {$site_wide_admin_p == 1 || $department_admin_p > 0} {
	append return_string "[ad_space] \[ <a href=\"/education/util/group-login.tcl?group_type=edu_department&group_id=$department_id\&return_url=[edu_url]department/admin/\">admin page</a> \]"
    }

    incr count
}

if {$count == 0} {
    append return_string "There are currently no departments in the system."
} else {
    append return_string "<br>"
}

append return_string "
</ul>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string












