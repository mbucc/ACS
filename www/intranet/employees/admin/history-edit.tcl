# $Id: history-edit.tcl,v 3.1.4.2 2000/03/17 07:13:34 mbryzek Exp $
# /www/intranet/employees/admin/history-edit.tcl
# created: january 1st 2000
# ahmedaa@mit.edu
# Modified by mbryzek@arsdigita.com in January 2000 to support new group-based intranet

# allows and administrator to edit the work percentage
# history of an employee

ad_maybe_redirect_for_registration

set_form_variables 0
# user_id 

if { ![exists_and_not_null user_id] } {
    ad_return_error "Missing user id" "We weren't able to determine what user you want information for."
    return
}

set db [ns_db gethandle]

# when did this user start
set start_date [database_to_tcl_string_or_null $db \
	"select start_date from im_employee_info where user_id = $user_id"]

if { [empty_string_p $start_date] } {
    set return_url history-edit.tcl?[export_url_vars user_id]
    ad_return_error "Missing Start Date" "You must <a href=info-update.tcl?[export_url_vars user_id return_url]>set this employee's start date</a> before editing the history"
    return
}

# Get the user's name and employment start date
set selection [ns_db 1row $db \
	"select initcap(u.first_names) || ' ' || initcap(u.last_name) as user_name, info.start_date
          from users u, im_employee_info info
         where u.user_id = $user_id
           and u.user_id = info.user_id"]
set_variables_after_query

# Get the list of all the start blocks and percentages for this employee
set selection [ns_db select $db \
	"select percentage_time, start_block,
                to_char(start_block, 'Month ddth, YYYY') as pretty_start_block
           from im_employee_percentage_time 
          where user_id = $user_id 
            and percentage_time is not null 
          order by start_block asc"]

set list_of_changes_html ""

set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]
set old_percentage ""
set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $counter == 0 } {
	append list_of_changes_html "
<tr>
  <td valign=top>History starts on week beginning $pretty_start_block at $percentage_time %</td>
</tr>
"
	incr counter
    } else {
	if { [string compare  $old_percentage $percentage_time] != 0 } {
	    append list_of_changes_html "
<tr>
  <td>On week starting $pretty_start_block, changed to $percentage_time %</td>
</tr>
"
        }
        set old_percentage $percentage_time
    } 
}


# Let's setup an html select box to get the next start_block 
#   (that is, the next sunday including today if today is sunday)
set selection [ns_db select $db \
	"select to_char(start_block, 'ddth Month, YYYY') as start_block_pretty, start_block 
           from im_start_blocks 
          where start_block >= (select next_day(to_date('$start_date','YYYY-MM-DD')- 60, 'SUNDAY') from dual)"]

set block_start_html "<select name=start_block>\n"
set block_end_html "<select name=stop_block>\n  <option value=\"forever\">Indefinite</option>"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append block_end_html "  <option value=\"$start_block\"> $start_block_pretty</option>\n"
    append block_start_html "  <option value=\"$start_block\"> $start_block_pretty</option>\n"
}

append block_end_html "</select>"
append block_start_html "</select>"

set page_title "Edit employee history"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Employees" ] [list view.tcl?[export_url_vars user_id] "One employee"] [list "history.tcl?[export_url_vars user_id]" "History"] "Edit"]

ReturnHeaders
ns_write "
[ad_partner_header]

<h3>Current History:</h3>
<table>
[util_decode $list_of_changes_html "" "<tr><td><i>No history</i></td></tr>" $list_of_changes_html]
</table>
<br>
<h3>Edit:</h3>
<form method=post action=history-edit-2.tcl>
[export_form_vars user_id]
<table>
<tr>
<th align=right>Percentage working time:</th>
<td><select name=percentage>
[html_select_options $percentages [value_if_exists percentage]]
</select>
</td>
</tr>

<tr>
 <th align=right>Starts at this percentage on:</th>
<td>
$block_start_html
</td>
</tr>

<tr>
 <th align=right>Will work at this percentage until:</th>
<td>
$block_end_html
</td>
</tr>

<tr>
<th valign=top align=right>Note:</th>
<td>
<textarea name=note cols=50 rows=5 wrap=soft></textarea
</td>
</tr>

</table>
<br>
<center>
<input type=submit value=\"Update history\">
</center>
</form>

[ad_partner_footer]
"