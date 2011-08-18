# $Id: history.tcl,v 3.2.2.2 2000/04/28 15:11:06 carsten Exp $
#
# File: /www/intranet/employees/admin/history.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#

ad_maybe_redirect_for_registration

set_form_variables 0
# user_id 
# return_url optional

set db_list [ns_db gethandle main 2]
set db [lindex $db_list 0]
set db2 [lindex $db_list 1]

# This page is restricted to only site/intranet admins or the user 
if { ![im_is_user_site_wide_or_intranet_admin $db] } {
    ad_returnredirect ../
    return
}

set user_name [database_to_tcl_string_or_null $db \
	"select first_names || ' ' || last_name from users where user_id=$user_id"]
if { [empty_string_p $user_name] } {
    ad_return_error "User #$user_id doesn't exist" "We couldn't find the user with user id of $user_id."
    return
}


#make selection
set selection [ns_db select $db \
	"select percentage_time, start_block 
           from im_employee_percentage_time 
          where user_id = $user_id 
            and start_block < to_date(sysdate, 'YYYY-MM-DD') 
          order by start_block desc"]

set result [list]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend result [list $start_block "" $percentage_time]
}


set user_name [database_to_tcl_string $db \
	"select initcap(first_names) || ' ' || initcap(last_name) from users where user_id = $user_id"]

set selection [ns_db select $db \
	"select percentage_time, start_block ,
                to_char(start_block, 'Month ddth, YYYY') as pretty_start_block
           from im_employee_percentage_time 
          where user_id = $user_id 
            and percentage_time is not null 
          order by start_block asc"]

set list_of_changes_html ""
set graph_return_html ""

set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]

set old_percentage ""
set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $counter == 0 } {
	set list_of_changes_html "<h4>Summary</h4><table>"
	append list_of_changes_html "
<tr>
  <td valign=top>History starts on week beginning $pretty_start_block at ${percentage_time}%</td>
</tr>
"
	incr counter
    } else {
	if { [string compare  $old_percentage $percentage_time] != 0 } {
	    if { ![catch {set correct_grammar [database_to_tcl_string $db2 "select 'will change to' from dual where sysdate < to_date('$start_block', 'YYYY-MM-DD')"] } errmsg] } {
		
	    } else {
		set correct_grammar "changed to"
	    }
	    append list_of_changes_html "
<tr>
  <td>On week starting $pretty_start_block, $correct_grammar $percentage_time %</td>
</tr>
"
        }
    }
    set old_percentage $percentage_time
}
ns_db releasehandle $db2

append list_of_changes_html "</table>"

set no_history_message_html ""

if { $counter == 0 } {
    set no_history_message_html "<br><br><blockquote>There is no percentage employment history for $user_name."
    set start_date [database_to_tcl_string_or_null $db \
	    "select decode(start_date, NULL ,'', to_char(start_date, 'Month ddth, YYYY')) || 
                    decode(percentage, NULL, '', 0, '', ' at '||percentage||'%.') as start_date 
               from im_employee_info
              where user_id =  $user_id"]

    if { ![empty_string_p $start_date] } {
	append no_history_message_html " It is known that he/she started on $start_date"
    } else {
	append no_history_message_html " This person's starting percentage is also not listed."
    }
    append no_history_message_html "</blockquote>\n"

} else {
    set graph_return_html "
    <br><h4>Graph:up until [database_to_tcl_string $db "select to_char(sysdate, 'Month ddth, YYYY') from dual"]</h4>
    <br>
    
    [gr_sideways_bar_chart -bar_color_list "muted-green"  -display_values_p "t" -bar_height "10" -left_heading "<b><u>Week starting</u><b>"  -right_heading "<b><u>Percentage</u></b>" $result]
"
}

ns_db releasehandle $db

set page_title "Employee History for $user_name"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Employees" ] [list view.tcl?[export_url_vars user_id] "One employee"] "History"]

set page_body "
(<a href=history-edit.tcl?[export_url_vars user_id]>Edit</a>)

$no_history_message_html
$list_of_changes_html
$graph_return_html
"


ns_return 200 text/html [ad_partner_return_template]