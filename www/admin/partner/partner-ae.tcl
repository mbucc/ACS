# $Id: partner-ae.tcl,v 3.0 2000/02/06 03:26:35 ron Exp $
set_the_usual_form_variables 0
# partner_id if we're editing

set db [ns_db gethandle]

if  {[info exists partner_id] && ![empty_string_p $partner_id]} {
    set selection [ns_db 1row $db "select *
		                   from ad_partner 
                                   where partner_id='$QQpartner_id'"]
    set_variables_after_query
    set page_title "Edit partner"
} else {
    set partner_id [database_to_tcl_string $db "select ad_partner_partner_id_seq.nextVal from dual"]
    set page_title "Add partner"
    set group_id ""
}


set selection [ns_db select $db \
	"select group_id as id, group_name
           from user_groups
          order by lower(group_name)"]
set inner [list ""]
set outer [list "-- Please Select --"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend inner $id
    lappend outer $group_name
}



set context_bar [ad_context_bar_ws [list "index.tcl" "Partner manager"] [list "partner-view.tcl?[export_url_vars partner_id]" "One partner"] "$page_title"]

set partner_vars [ad_partner_list_all_vars]       

set table "
<form method=post action=\"partner-ae-2.tcl\">
[export_form_vars return_url]
<input type=hidden name=\"dp.ad_partner.partner_id\" value=$partner_id>

<table>
"

foreach pair $partner_vars {
    append table "
<tr>
  <td>[lindex $pair 1]</td>
  <td><input type=text size=40 name=\"dp.ad_partner.[lindex $pair 0]\" [export_form_value [lindex $pair 0]]></td>
</tr>

"
}

append page_body "
$table

<tr>
  <td>Group</td>
  <td><select name=dp.ad_partner.group_id>
[ad_generic_optionlist $outer $inner $group_id]
</select></td>
</tr>

</table>

<center><input type=submit value=\" $page_title \"></center>
</form>

"

ns_return 200 text/html [ad_partner_return_template]