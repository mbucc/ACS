# history-edit.tcl,v 3.12.2.6 2000/09/22 01:38:34 kevin Exp
# /www/intranet/employees/admin/history-edit.tcl
# created: 
# 
# /www/intranet/employees/admin/history-edit.tcl
ad_page_contract {
    Modified by mbryzek@arsdigita.com in January 2000 to support new group-based intranet
    
    allows and administrator to edit the work percentage
    history of an employee  

    @author ahmedaa@mit.edu
    @creation-date january 1st 2000
    @cvs-id history-edit.tcl,v 3.12.2.6 2000/09/22 01:38:34 kevin Exp
    @param user_id the user id
} {
    user_id
}


ad_maybe_redirect_for_registration



# when did this user start
set start_date [db_string get_start_date "select start_date from im_employee_info where user_id = :user_id" -default ""]

if { [empty_string_p $start_date] } {
    set return_url history-edit.tcl?[export_url_vars user_id]
    ad_return_error "Missing Start Date" "You must <a href=view?[export_url_vars user_id]>set this employee's start date</a> before editing the history"
    return
}

# Get the user's name and employment start date
db_1row get_user_info \
	"select initcap(u.first_names) || ' ' || initcap(u.last_name) as user_name, info.start_date
          from users u, im_employee_info info
         where u.user_id = :user_id
           and u.user_id = info.user_id"


# Get the list of all the start blocks and percentages for this employee

set list_of_changes_html ""

set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]
set old_percentage ""
set counter 0
db_foreach get_history_info "select percentage_time, start_block,
                to_char(start_block, 'Month ddth, YYYY') as pretty_start_block
           from im_employee_percentage_time 
          where user_id = :user_id 
            and percentage_time is not null 
          order by start_block asc" {
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

# We do this separately in case the employees start date is before our first start block!
set first_start_block [db_string  get_max_start_block 	"select max(start_block) from im_start_blocks where start_block < to_date(:start_date,'yyyy-mm-dd')" -default ""]

if { [empty_string_p $first_start_block] } {
    set first_start_block [db_string  get_first_start_block \
	    "select min(start_block) from im_start_blocks" -default ""]
    if { [empty_string_p $first_start_block] } {
	ad_return_error "Missing Start Blocks" "It looks like no start blocks were loaded into the data model"
	return
    }
}

# pull out the start blocks closest to today's date to use as 
# a default for both the select bars

db_1row get_block_stuff \
	"select (select max(start_block) from im_start_blocks where start_block <= sysdate) as default_start_block,
                (select min(start_block) from im_start_blocks where start_block > sysdate) as default_end_block
           from dual"



set block_start_html "<select name=start_block>\n"
set block_end_html "<select name=stop_block>\n  <option value=\"forever\">Indefinite</option>"
db_foreach getmoreblockstuff 	"select to_char(start_block, 'Month DD, YYYY') as start_block_pretty, start_block 
from im_start_blocks 
          where start_block >= :first_start_block
            and start_block <= add_months(sysdate,18)" {

    append block_start_html "  <option value=\"$start_block\"[util_decode $start_block $default_start_block " selected" ""]> $start_block_pretty</option>\n"
    append block_end_html "  <option value=\"$start_block\"[util_decode $start_block $default_end_block " selected" ""]> $start_block_pretty</option>\n"
}

append block_end_html "</select>"
append block_start_html "</select>"

set page_title "Edit employee history for $user_name"
set context_bar [ad_context_bar_ws [list "index.tcl" "Employees" ] [list view.tcl?[export_url_vars user_id] "One employee"] [list "history.tcl?[export_url_vars user_id]" "History"] "Edit"]


doc_return  200 text/html "
[im_header]

<h3>Current History:</h3>
<table>
[util_decode $list_of_changes_html "" "<tr><td><i>No history</i></td></tr>" $list_of_changes_html]
</table>
<br>
<h3>Edit:</h3>
<form method=post action=history-edit-2>
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

[im_footer]
"








