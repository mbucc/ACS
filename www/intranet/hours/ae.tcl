# /www/intranet/hours/ae.tcl

ad_page_contract {
    Displays form to let user enter hours

    @param on_which_table 
    @param on_what_id
    @param julian_date 
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id ae.tcl,v 3.9.2.9 2001/02/06 02:39:06 mbryzek Exp
} {
    { on_which_table "im_projects" }
    { on_what_id:integer "" }
    { julian_date "" }
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]

if { [empty_string_p $julian_date] } {
    set julian_date [db_string sysdate_as_julian \
	    "select to_char(sysdate,'J') from dual"]
}

db_1row user_name_and_date \
	"select first_names || ' ' || last_name as user_name,
                to_char(to_date(:julian_date, 'J'), 'fmDay fmMonth fmDD, YYYY') as pretty_date
           from users
          where user_id = :user_id" 

if { ![empty_string_p $on_what_id] } {


    set one_project_only_p 1
    set statement_name "hours_for_one_group"
    set sql "select g.group_name, g.group_id,
	            h.hours, h.note, h.billing_rate
               from user_groups g, im_hours h
              where g.group_id = :on_what_id
                and g.group_id = h.on_what_id(+)
                and :on_which_table = h.on_which_table(+)
                and h.user_id(+) = :user_id
                and to_date(:julian_date, 'J') = h.day(+)
              order by upper(group_name)"

} else {
    set one_project_only_p 0

    set statement_name "hours_for_groups"
    set sql "select g.group_name, g.group_id,
	            h.hours, h.note, h.billing_rate, p.parent_id
               from user_groups g, im_hours h, im_projects p
              where h.day(+) = to_date(:julian_date, 'J')
                and g.group_id=p.group_id
                and h.user_id(+) = :user_id
                and g.group_id = h.on_what_id(+)
                and :on_which_table = h.on_which_table(+)
                and p.project_status_id in (select project_status_id
                                              from im_project_status
                                             where upper(project_status) in ('OPEN','FUTURE'))
                and p.group_id in (select map.group_id 
                                     from user_group_map map
                                    where map.user_id = :user_id
                                    UNION
                                   select h.on_what_id
                                     from im_hours h
                                    where h.user_id = :user_id
                                      and on_which_table = :on_which_table
                                      and (h.hours is not null
                                           OR h.note is not null)
                                      and h.day = to_date(:julian_date, 'J'))
            order by upper(group_name)"

}

set page_title "Hours for $pretty_date"
set context_bar [ad_context_bar_ws [list index?[export_url_vars on_which_table] "Hours"] "Add hours"]

set options [list "<a href=index?[export_ns_set_vars url [list julian_date]]>Log hours for a different day</a>"]

if { ![empty_string_p $return_url] } {
    lappend options "<a href=$return_url>Go back to where you were</a>"
}

set page_body "
<center>\[
[join $options " | "]
\]</center>

<form method=post action=ae-2>
[export_form_vars julian_date return_url on_which_table]

"

set results ""
set ctr 0

if {![info exists parent_id]} {
    set parent_id ""
}


db_foreach $statement_name $sql {
    append results "<tr>\n"
    if { [empty_string_p $parent_id] } {
	append results "  <td bgcolor=#cccccc COLSPAN=2 align=center>$group_name</td>\n"
    } else {
	append results "  <td bgcolor=#99cccc COLSPAN=2>$group_name</td>\n"
    }
    append results "
</tr>
<tr VALIGN=top bgcolor=#efefef>
  <td ALIGN=right bgcolor=#efefef>Hours:</TD>
  <td><INPUT NAME=hours.${group_id}.hours size=5 MAXLENGTH=5 [export_form_value hours]></TD>
</TR>
<tr VALIGN=top bgcolor=#efefef>
  <td>Work done:</TD>
  <td><TEXTAREA NAME=hours.${group_id}.note WRAP=SOFT COLS=50 ROWS=6>[ns_quotehtml [value_if_exists note]]</TEXTAREA></TD>
</TR>
<tr bgcolor=#efefef>
   <td ALIGN=right bgcolor=#efefef>Billing Rate:</TD>
   <td>\$<INPUT NAME=hours.${group_id}.billing_rate size=6 MAXLENGTH=6 [export_form_value billing_rate]> 
    <FONT size=-1>(Leave blank if not billing hourly)</FONT></TD>
</TR>    
"
    incr ctr
}

if { [empty_string_p $results] } {
    append page_body "
<b>You currently do not belong to any projects</b>

<p><a href=other-projects?[export_url_vars on_which_table julian_date]>Add hours on other projects</A>
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
<td COLSPAN=2 align=center bgcolor=#d0d0d0>
<a href=other-projects?[export_url_vars on_which_table julian_date]>Add hours on other projects</A>
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



doc_return  200 text/html [im_return_template]
