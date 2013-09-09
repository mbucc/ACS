ad_page_contract {
    Writes termination information to the database

    @author berkeley@arsdigita.com
    @creation-date Tue Jul 11 20:34:39 2000
    @cvs-id employee-termination-2.tcl,v 3.10.2.12 2000/09/22 01:38:33 kevin Exp
    @param dp.im_employee_info.user_id The user we're terminating
    @param dp.im_employee_info.termination_reason Optional termination reason
    @param dp.im_employee_info.voluntary_termination_p Optional - did they leave voluntarily
    @param termination_date Optional termination date
    @param return_url The url to bounce back to
} {
    dp.im_employee_info.user_id:naturalnum
    dp.im_employee_info.termination_date:optional
    { dp.im_employee_info.termination_reason "" }
    { dp.im_employee_info.voluntary_termination_p "" }
    { dp.im_employee_info.termination_date.date ""}
    { termination:array,date }
    { return_url "" }
}


#deprecated by the new date functionality of ad_page_contract
#      { ColValue.termination.month "" } 
#      { ColValue.termination.day "" } 
#      { ColValue.termination.year "" } 


set user_id ${dp.im_employee_info.user_id}

set termination_date $termination(date)

set exception_count 0

if { [string length ${dp.im_employee_info.termination_reason}] >= 4000 } {
    incr exception_count
    append exception_text "<li>The termination reason must be fewer than 4000 characters\n"
}
if { [info exists termination(date)] } {

    ns_set put [ns_getform] dp.im_employee_info.termination_date  $termination(date)

} else {
    incr exception_count 
    append exception_text "<li>You must specify a date for termination."
}

# This page is restricted to only site/intranet admins
if { ![im_is_user_site_wide_or_intranet_admin] } {
    ad_return_error "Access denied" "You must be an administrator of [ad_parameter SystemName] to see this page"
    return
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set employee_name [db_string getname \
	"select first_names || ' ' || last_name from users where user_id=:user_id"]

# Check for subordinates
set num_subordinates [db_string get_num_subordinates \
	"select count(*)
	   from im_employees_active u
	  where u.supervisor_id = :user_id"]

# Record what we do to display to the user
set actions [list]

db_transaction {

# Remove all alocations after this date
db_dml delete4fire1 "delete from im_allocations 
                where start_block >= :termination_date
                  and user_id=:user_id"
lappend actions "<li> Deleted all allocations for this employee starting with [util_AnsiDatetoPrettyDate $termination_date]"

db_dml delete4fire2 "delete from im_employee_percentage_time 
                where start_block >= :termination_date
                  and user_id=:user_id"
lappend actions "<li> Deleted all percentages for this employee starting with [util_AnsiDatetoPrettyDate $termination_date]"
    
db_dml delete4fire3 "delete from user_group_map ugm 
                where ugm.user_id=:user_id 
                  and exists (select 1 
                                from user_groups ug 
                               where ug.group_id=ugm.group_id 
                                 and ug.group_type='[ad_parameter IntranetGroupType intranet intranet]')"
lappend actions "<li> Removed the user from all intranet groups"

# Remove the person from the site-wide admin and intranet admin groups if neccessary
set admin_group_id_list [list]
set group_id [ad_administration_group_id "intranet" ""]
if { ![empty_string_p $group_id] } {
    lappend admin_group_id_list $group_id
}
set group_id [ad_administration_group_id "site_wide" ""]
if { ![empty_string_p $group_id] } {
    lappend admin_group_id_list $group_id
}

if { [llength $admin_group_id_list] > 0 } {
    lappend actions "<li> Removed the user from the site-wide administration and intranet administration groups"
    db_dml delete4fire4 "delete from user_group_map where user_id=:user_id and group_id in ([join $admin_group_id_list ", "])"
}

# user_id is already in the form - we can use it directly to bind
dp_process -where_clause "user_id=:user_id"

lappend actions "<li> Updated the employee's record to reflect the specified termination information"

}

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/employees/admin/index"
}

if { $num_subordinates > 0 } {
    # Need to change the supervisor
    lappend actions "<p><li>This employee supervised [util_commify_number $num_subordinates] [util_decode $num_subordinates 1 "employee" "employees"]. You should <a href=change-subordinates?from_user_id=$user_id&[export_url_vars return_url]>assign a new supervisor</a>."
} else {
    lappend actions "<p><li><a href=$return_url>Go back to where you were</a>"
}

db_release_unused_handles

set page_title "Termination information for $employee_name"
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list "/shared/community-member?[export_url_vars user_id]" "One user"] "Terminated"]

set page_body "
<ul>
[join $actions "\n"]
</ul>
"

doc_return  200 text/html [im_return_template]
