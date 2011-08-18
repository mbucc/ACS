# $Id: ae.tcl,v 3.1.4.1 2000/03/17 08:22:56 mbryzek Exp $
# File: /www/intranet/hours/ae.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Displays form to let user enter hours
#

set_the_usual_form_variables
# on_which_table
# julian_date (defaults to today)
# on_what_id (optional)

set db [ns_db gethandle]

if { ![exists_and_not_null on_which_table] } {
    set on_which_table im_projects
    set QQon_which_table im_projects
}

if { ![exists_and_not_null julian_date] } {
    set julian_date [database_to_tcl_string $db \
	    "select to_char(sysdate,'J') from dual"]

}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set selection [ns_db 1row $db \
	"select first_names || ' ' || last_name as user_name,
                to_char(to_date($julian_date, 'J'), 'fmDay fmMonth fmDD, YYYY') as pretty_date
           from users
          where user_id = $user_id"]    

set_variables_after_query

if { [exists_and_not_null on_what_id] } {

    set one_project_only_p 1
    set selection [ns_db select $db \
	    "select g.group_name, g.group_id,
	            h.hours, h.note, h.billing_rate
               from user_groups g, im_hours h
              where g.group_id = $on_what_id
                and g.group_id = h.on_what_id(+)
                and '$QQon_which_table' = h.on_which_table(+)
                and h.user_id(+) = $user_id
                and to_date($julian_date, 'J') = h.day(+)
              order by upper(group_name)"]

} else {
    set one_project_only_p 0

    set selection [ns_db select $db \
	    "select g.group_name, g.group_id,
	            h.hours, h.note, h.billing_rate
               from user_groups g, im_hours h, im_projects p
              where h.day(+) = to_date($julian_date, 'J')
                and g.group_id=p.group_id
                and h.user_id(+) = $user_id
                and g.group_id = h.on_what_id(+)
                and '$QQon_which_table' = h.on_which_table(+)
                and p.project_status_id in (select project_status_id
                                              from im_project_status
                                             where upper(project_status) in ('OPEN','FUTURE'))
                and p.group_id in (select map.group_id 
                                     from user_group_map map
                                    where map.user_id = $user_id
                                    UNION
                                   select h.on_what_id
                                     from im_hours h
                                    where h.user_id = $user_id
                                      and on_which_table = '$QQon_which_table'
                                      and (h.hours is not null
                                           OR h.note is not null)
                                      and h.day = to_date($julian_date, 'J'))
            order by upper(group_name)"]

}

set page_title "Hours for $pretty_date"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" Intranet] [list index.tcl?[export_url_vars on_which_table] "Hours"] "Add hours"]

set page_body "
<form method=post action=ae-2.tcl>
[export_form_vars julian_date return_url on_which_table]

"

set results ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append results "

<tr>
<td bgcolor=#d0d0d0 COLSPAN=2><B>$group_name</B></TD></TR>
<tr VALIGN=top bgcolor=#efefef>
<td ALIGN=right bgcolor=#efefef>Hours:</TD>
<td><INPUT NAME=hours_${group_id}.hours size=5 MAXLENGTH=5 [export_form_value hours]></TD>
</TR>
<tr VALIGN=top bgcolor=#efefef>
<td>Work done:</TD>
<td><TEXTAREA NAME=hours_${group_id}.note WRAP=SOFT COLS=50 ROWS=6>[ns_quotehtml [value_if_exists note]]</TEXTAREA>
</TD>
</TR>
<tr bgcolor=#efefef>
<td ALIGN=right bgcolor=#efefef>Billing Rate:</TD>
<td>\$<INPUT NAME=hours_${group_id}.billing_rate size=6 MAXLENGTH=6 [export_form_value billing_rate]> 
<FONT size=-1>(Leave blank if not billing hourly)</FONT></TD>
</TR>


"
}

if { [empty_string_p $results] } {
    append page_body "
<b>You currently do not belong to any projects</b>

<p><a href=other-projects.tcl?[export_url_vars on_which_table julian_date]>Add hours on other projects</A>
"
} else {
    set page_body "
$page_body
<center>
<table border=0 cellpadding=4 cellspacing=2>
$results 
"
    if {! $one_project_only_p} {
	append page_body "
<tr>
<td COLSPAN=2 bgcolor=#d0d0d0>
<a href=other-projects.tcl?[export_url_vars on_which_table julian_date]>Add hours on other projects</A>
</TD>
</TR>
"
    }

    append page_body "
</table>

<p><INPUT TYPE=Submit VALUE=\" Add hours \">
</form>
</center>
"
}


ns_return 200 text/html [ad_partner_return_template]
