# $Id: add.tcl,v 3.1.4.1 2000/03/17 08:22:47 mbryzek Exp $
# File: /www/intranet/allocations/add.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# allows someone to enter in an employees allocations
#

set_the_usual_form_variables 0

# maybe group_id, start_block, allocation_id, user_id, 
# maybe return_url

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]

if ![info exists allocation_id] {
    set allocation_id [database_to_tcl_string $db "select im_allocations_id_seq.nextval from dual"]
} else {
    set selection [ns_db 1row $db "select user_id as allocation_user_id, note
from im_allocations
where allocation_id = $allocation_id
and start_block = '$start_block'"]
    set_variables_after_query
}

set page_title "Enter an allocation"
set context_bar "[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Allocations"] "Enter allocation"]"

ns_return 200 text/html "
[ad_partner_header]

<form method=POST action=\"add-2.tcl\"> 
[export_form_vars allocation_id return_url]
<table>
<tr><th valign=top align=right>Project</th>
<td><select name=group_id>
[db_html_select_value_options  $db "select 
p.group_id, ug.group_name 
from im_projects p, user_groups ug, im_project_status ps
where ps.project_status <> 'deleted'
and ps.project_status_id = p.project_status_id
and ug.group_id = p.group_id
order by lower(group_name)" [value_if_exists group_id]]
</select>
</td></tr>

<tr><th valign=top align=right>Employee</th>
<td>
<select name=allocated_user_id>
<option value=\"\">Not decided</option>
[im_employee_select_optionlist $db [value_if_exists allocation_user_id]]
</select>
</td></tr>

<tr><th valign=top align=right>Start week beginning (Sunday):</th>
<td>
<select name=start_block>
[im_allocation_date_optionlist $db [value_if_exists start_block]]
</select>
</td></tr>

<tr><th valign=top align=right>End week beginning (Sunday):</th>
<td>
<select name=end_block>
<option></option>
[im_allocation_date_optionlist $db [value_if_exists start_block]]
</select>
</td></tr>

<tr><th valign=top align=right>Percentage time</th>
<td><select name=percentage_time>
[html_select_options $percentages [value_if_exists percentage_time]]
</select>
</td></tr>
</select>

<tr><th valign=top align=right>Note</th>
<td><textarea name=note cols=40 rows=8 wrap=soft>[value_if_exists note]</textarea></td></tr>

</table>

<p>
<center>
<input type=submit value=\"Submit\">
</center>
</form>
<p>
[ad_partner_footer]"
