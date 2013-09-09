# /www/intranet/employees/org-chart-chain.tcl

ad_page_contract {
    Shows all the specified users supervisors (chain of command...)

    @param user_id whose bosses we're looking for

    @author by mbryzek@arsdigita.com
    @creation-date 4/4/2000

    @cvs-id org-chart-chain.tcl,v 3.6.6.6 2000/09/22 01:38:30 kevin Exp
} {
    user_id:integer
}


set user_name [db_string  user_name_retrieve \
	"select first_names || ' ' || last_name from im_employees_active where user_id=:user_id"\
-default ""]

if { [empty_string_p $user_name] } {
    ad_return_error "Employee not found" "Employee, #$user_id, could not be found."
    return
}

set page_title "Who $user_name reports to" 
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list ../users/view?[export_url_vars user_id] "One employee"] "Reports to chain"]

# there's a weird case when a manager has left the company.  we can't just leave him blank because
# it screws the chart up, therefore put in a placeholder "vacant"

set last_level 0   ;#level of last employee
set vacant_position ""

set query_post_select "
from im_employee_info
where im_employee_info.termination_date is null 
start with user_id = :user_id
connect by user_id = PRIOR supervisor_id"

# We need to grab max_level first since the query starts with the
# last employee
set max_level [db_string max_level_retrieve \
	"select max(level) $query_post_select"]

set supervisor_sql "select 
    supervisor_id, 
    user_id, 
    replace(lpad(' ', ($max_level - level) * 6),' ','&nbsp;') as spacing,
    im_name_from_user_id(user_id) as employee_name,
    level,
    ad_group_member_p(user_id, [im_employee_group_id]) as currently_employed_p
$query_post_select"
        
set people_list [list]

db_foreach supervisor_display $supervisor_sql {
    if { $currently_employed_p == "t" } {
        if { $vacant_position != "" && $last_level < $level } {
            lappend people_list $vacant_position
	}
        lappend people_list "$spacing<a href=../users/view?[export_url_vars user_id]>$employee_name</a><br>\n"
        set vacant_position ""
    } else {
        set vacant_position $spacing
        append vacant_position "Position Vacant</i><br>\n"
    }
    set last_level $level
}

set page_body "<blockquote>"

# run through starting with the ceo (last person in the list...)
for { set i [expr [llength $people_list] - 1] } { $i >= 0 } { set i [expr $i - 1] } {
    append page_body [lindex $people_list $i]
}

append page_body "</blockquote>\n"



doc_return  200 text/html [im_return_template]
