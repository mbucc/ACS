# $Id: ae.tcl,v 3.2.2.1 2000/03/17 08:23:11 mbryzek Exp $
# File: /www/intranet/projects/ae.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: form to add a new project or edit an existing one
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# group_id (if we're editing)
# return_url (optional)

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set db [ns_db gethandle]
if { [exists_and_not_null group_id] } {
    set selection [ns_db 1row $db \
	    "select p.parent_id, p.customer_id, g.group_name, p.project_type_id, p.project_status_id, p.description, 
                    p.project_lead_id, p.supervisor_id, g.short_name, 
                    to_char(p.start_date,'YYYY-MM-DD') as start_date,
                    to_char(p.end_date,'YYYY-MM-DD') as end_date
               from im_projects p, user_groups g
              where p.group_id=$group_id
                and p.group_id=g.group_id"]

    set_variables_after_query
    set page_title "Edit project"
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Projects"] [list "view.tcl?[export_url_vars group_id]" "One project"] $page_title]

    if { [empty_string_p $start_date] } {
	set start_date $todays_date
    }
    if { [empty_string_p $end_date] } {
	set end_date $todays_date
    }

} else {

    if { ![exists_and_not_null parent_id] } {
	# A brand new project (not a subproject)
	set parent_id ""
	if { ![exists_and_not_null customer_id] } {
	    set customer_id ""
	}
	set project_type_id ""
	set project_status_id ""
	set page_title "Add project"
	set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Projects"] $page_title]
    } else {
	# This means we are adding a subproject - let's select out some defaults for this page
	set selection [ns_db 1row $db \
		"select p.customer_id, p.project_type_id, p.project_status_id
                   from im_projects p
                  where p.group_id=$parent_id"]
	set_variables_after_query

	set page_title "Add subproject"
	set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Projects"] [list "view.tcl?group_id=$parent_id" "One project"] $page_title]
    }
    set start_date $todays_date
    set end_date $todays_date
    set project_lead_id ""
    set supervisor_id ""
    set description ""

    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id

    set group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
}

set page_body "
<form method=post action=ae-2.tcl>
[export_form_vars return_url group_id dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]

[im_format_number 1] Project name: 
<br><dd><input type=text size=45 name=dp_ug.user_groups.group_name [export_form_value group_name]>

<p>[im_format_number 2] Project short name:
<br><dd><input type=text size=45 name=dp_ug.user_groups.short_name [export_form_value short_name]>

<p>[im_format_number 3] Customer: 
[im_customer_select $db "dp.im_projects.customer_id" $customer_id Current]
(<a href=../customers/ae.tcl?return_url=[ns_urlencode [ad_partner_url_with_query]]>Add a customer</a>)
<br><dd><font size=-1>Note: Only current customers are listed</font>

<p>[im_format_number 4] Project type:
[im_project_type_select $db "dp.im_projects.project_type_id" $project_type_id]

<p>[im_format_number 5] Project status:
[im_project_status_select $db "dp.im_projects.project_status_id" $project_status_id]

<p>[im_format_number 6] Project leader:
[im_user_select $db "dp.im_projects.project_lead_id" $project_lead_id]

<p>[im_format_number 7] Team leader or supervisor:
[im_user_select $db "dp.im_projects.supervisor_id" $supervisor_id]

<p>[im_format_number 8] Start date:
[philg_dateentrywidget start $start_date]

<p>[im_format_number 9] End date:
[philg_dateentrywidget end $end_date]

<p>[im_format_number 10] Parent project:
[im_project_parent_select $db "dp.im_projects.parent_id" $parent_id $group_id Open]
<br><dd><font size=-1>Note: Only open projects are listed</font>
"

set ctr 11

set selection [ns_db select $db \
	"select t.url_type_id, t.to_ask, m.url
           from im_url_types t, im_project_url_map m
          where t.url_type_id=m.url_type_id(+)
            and $group_id=m.group_id(+)
          order by t.display_order, lower(t.url_type)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append page_body "
<p>[im_format_number $ctr] $to_ask:
<br><dd><input type=text size=45 name=url_$url_type_id [export_form_value url]>
"
    incr ctr
}


append page_body "
<p>[im_format_number $ctr] Short description of this project:
<br><dd><textarea name=dp.im_projects.description rows=6 cols=45 wrap=soft>[philg_quote_double_quotes $description]</textarea>
 
<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]