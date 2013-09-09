# /www/intranet/projects/ae.tcl

ad_page_contract {
    Purpose: form to add a new project or edit an existing one
    
    @param group_id group id
    @param parent_id the parent project id
    @param return_url the url to return to
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id ae.tcl,v 3.15.2.14 2001/01/13 23:46:52 kevin Exp
} {
    group_id:optional,integer
    parent_id:optional,integer
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if { [exists_and_not_null group_id] } {
    db_1row projects_info_query { 
	select p.parent_id, p.customer_id, g.group_name, p.project_type_id, p.project_status_id, 
	p.description, p.project_lead_id, p.supervisor_id, g.short_name, 
	to_char(p.start_date,'YYYY-MM-DD') as start_date, to_char(p.end_date,'YYYY-MM-DD') as end_date, 
	p.requires_report_p 
	from im_projects p, user_groups g where p.group_id=:group_id and p.group_id=g.group_id }

    set page_title "Edit project"
    set context_bar [ad_context_bar_ws [list ./ "Projects"] [list "view?[export_url_vars group_id]" "One project"] $page_title]

    if { [empty_string_p $start_date] } {
	set start_date $todays_date
    }
    if { [empty_string_p $end_date] } {
	set end_date $todays_date
    }

} else {

    if { ![exists_and_not_null parent_id] } {
	# A brand new project (not a subproject)
	set requires_report_p "t"
	set parent_id ""
	if { ![exists_and_not_null customer_id] } {
	    set customer_id ""
	}
	set project_type_id ""
	set project_status_id ""
	set page_title "Add project"
	set context_bar [ad_context_bar_ws [list ./ "Projects"] $page_title]
    } else {
	# This means we are adding a subproject - let's select out 
	# some defaults for this page
	db_1row projects_by_parent_id_query {
	    select p.customer_id, p.project_type_id, p.project_status_id
	    from im_projects p
	    where p.group_id=:parent_id }

	set requires_report_p "f"
	set page_title "Add subproject"
	set context_bar [ad_context_bar_ws [list ./ "Projects"] [list "view?group_id=$parent_id" "One project"] $page_title]
    }
    set start_date $todays_date
    set end_date $todays_date
    set project_lead_id ""
    set supervisor_id ""
    set description ""

    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id

    set group_id [db_nextval "user_group_sequence"]
}

set page_body "
<form method=post action=ae-2>
[export_form_vars return_url dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]
[export_form_vars -sign group_id]
[im_format_number 1] Project name: 
<br><dd><input type=text size=45 name=dp_ug.user_groups.group_name [export_form_value group_name]>

<p>[im_format_number 2] Project short name:
<br><dd><input type=text size=45 name=dp_ug.user_groups.short_name [export_form_value short_name]>

<p>[im_format_number 3] Customer: 
[im_customer_select "dp.im_projects.customer_id" $customer_id "" [list "Bid and Lost" "Past" "Declined"]]
(<a href=../customers/ae?return_url=[ns_urlencode [im_url_with_query]]>Add a customer</a>)

<p>[im_format_number 4] Project type:
[im_project_type_select "dp.im_projects.project_type_id" $project_type_id]

<p>[im_format_number 5] Project status:
[im_project_status_select "dp.im_projects.project_status_id" $project_status_id]

<p>[im_format_number 6] Project leader:
[im_user_select "dp.im_projects.project_lead_id" $project_lead_id]

<p>[im_format_number 7] Team leader or supervisor:
[im_user_select "dp.im_projects.supervisor_id" $supervisor_id]

<p>[im_format_number 8] Start date:
[philg_dateentrywidget start $start_date]

<p>[im_format_number 9] End date:
[philg_dateentrywidget end $end_date]

<p>[im_format_number 10] Parent project (if applicable):
[im_project_parent_select "dp.im_projects.parent_id" $parent_id $group_id "" [list Closed Deleted Inactive]]
"
set ctr 11

append page_body "
<p>[im_format_number $ctr] Short description of this project:
<br><dd><textarea name=dp.im_projects.description rows=6 cols=45 wrap=soft>[philg_quote_double_quotes $description]</textarea>
"
 

if { $user_admin_p } {
    incr ctr 
    set my_set [ns_set create]
    ns_set put $my_set "dp.im_projects.requires_report_p" $requires_report_p
    append page_body [bt_mergepiece "
<p>[im_format_number $ctr] Is a weekly report required for this project?
<br><dd>
  <input type=radio name=dp.im_projects.requires_report_p value=t> Yes
  <input type=radio name=dp.im_projects.requires_report_p value=f> No
" $my_set]
}

append page_body "
<p><center><input type=submit value=\"$page_title\"></center>
</form>
"



doc_return  200 text/html [im_return_template]
