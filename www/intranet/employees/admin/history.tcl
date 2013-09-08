# history.tcl,v 3.10.2.5 2000/09/22 01:38:34 kevin Exp
#
# File: /www/intranet/employees/admin/history.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# /www/intranet/employees/admin/history.tcl

ad_page_contract {

    @author berkeley@arsdigita.com
    @creation-date Wed Jul 12 13:46:28 2000
    @cvs-id history.tcl,v 3.10.2.5 2000/09/22 01:38:34 kevin Exp
    @param user_id The user whose history we're examining
    @param return_url Optional The url to go back to
} {
    user_id 
    return_url:optional
}


ad_maybe_redirect_for_registration

# This page is restricted to only site/intranet admins or the user 
if { ![im_is_user_site_wide_or_intranet_admin] } {
    ad_returnredirect ../
    return
}

set user_name [db_string   get_user_name  "select first_names || ' ' || last_name from users where user_id=:user_id" -default ""]

if { [empty_string_p $user_name] } {
    ad_return_error "User #$user_id doesn't exist" "We couldn't find the user with user id of $user_id."
    return
}

set termination_date [db_string get_termination_date  \
	"select termination_date from im_employee_info where user_id=:user_id" -default ""]

#make selection


set result [list]
db_foreach get_all_history "select percentage_time, start_block 
          from im_employee_percentage_time 
          where user_id = :user_id  
            and start_block < to_date(sysdate, 'YYYY-MM-DD') 
          order by start_block desc" {
    lappend result [list $start_block "" $percentage_time]
}

set user_name [db_string  get_new_user_name \
	"select initcap(first_names) || ' ' || initcap(last_name) from users where user_id = :user_id"]


set list_of_changes_html ""
set graph_return_html ""

set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]

set old_percentage ""
set counter 0
db_foreach select_summary "select percentage_time, start_block ,
                to_char(start_block, 'Month ddth, YYYY') as pretty_start_block
           from im_employee_percentage_time 
          where user_id = :user_id 
            and percentage_time is not null 
          order by start_block asc" {
    if { $counter == 0 } {
	set list_of_changes_html "<h4>Summary</h4><table>"
	if { ![empty_string_p $termination_date] } {
	append list_of_changes_html "
<tr>
  <td valign=top>This employee was terminated on [util_AnsiDatetoPrettyDate $termination_date]</td>
</tr>
"	    
	}
	append list_of_changes_html "
<tr>
  <td valign=top>History starts on week beginning $pretty_start_block at ${percentage_time}%</td>
</tr>
"
	incr counter
    } else {
	if { [string compare  $old_percentage $percentage_time] != 0 } {
	    if { ![catch {set correct_grammar [db_string get_correct_grammar "select 'will change to' from dual where sysdate < to_date(':start_block', 'YYYY-MM-DD')"] } errmsg] } {
		
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

append list_of_changes_html "</table>"

set no_history_message_html ""

if { $counter == 0 } {
    set no_history_message_html "<br><br><blockquote>There is no percentage employment history for $user_name."
    set start_date [db_string  get_start_date  \
	    "select decode(start_date, NULL ,'', to_char(start_date, 'Month ddth, YYYY')) || 
                    decode(percentage, NULL, '', 0, '', ' at '||percentage||'%.') as start_date 
               from im_employee_info
              where user_id =  :user_id" -default ""]

    if { ![empty_string_p $start_date] } {
	append no_history_message_html " It is known that he/she started on $start_date"
    } else {
	append no_history_message_html " This person's starting percentage is also not listed."
    }
    append no_history_message_html "</blockquote>\n"

} else {
    set graph_return_html "
    <br><h4>Graph:up until [db_string get_date "select to_char(sysdate, 'Month ddth, YYYY') from dual"]</h4>
    <br>
    
    [gr_sideways_bar_chart -bar_color_list "muted-green"  -display_values_p "t" -bar_height "10" -left_heading "<b><u>Week starting</u><b>"  -right_heading "<b><u>Percentage</u></b>" $result]
"
}


set page_title "Employee History for $user_name"
set context_bar [ad_context_bar_ws [list "index.tcl" "Employees" ] [list view.tcl?[export_url_vars user_id] "One employee"] "History"]

set page_body "
(<a href=history-edit?[export_url_vars user_id]>Edit</a>)

$no_history_message_html
$list_of_changes_html
$graph_return_html
"

doc_return  200 text/html [im_return_template]