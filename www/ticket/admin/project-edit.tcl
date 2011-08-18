# $Id: project-edit.tcl,v 3.2 2000/02/12 01:26:21 mbryzek Exp $
ad_page_variables { 
    {project_id {}} 
    {ascopy {}} 
    {ticket_return {/ticket/}}
    {return_url {/ticket/admin/index.tcl?}}
    {owning_group_id {}} 
    {preset_title {}} 
    {preset_title_long {}} 
    {target {project-edit-2.tcl}}
}

set db [ns_db gethandle]
set user_id [ad_get_user_id]
set context [list \
                 [list $ticket_return "Ticket Tracker"] \
                 [list "$return_url&ticket_return=[ns_urlencode $ticket_return]" "Administration"]]

if { ![empty_string_p $project_id] } {
    if {[regexp {^[ ]*[0-9]+[ ]*$} $project_id]} {    
        set selection [ns_db 1row $db "select tp.*,
            u.email, 
            u.first_names || ' ' || u.last_name as user_name
          from ticket_projects tp, users u
          where project_id = $project_id and u.user_id = tp.created_by"]
        if {[empty_string_p $selection]} {
            ad_return_complaint 1 "<li>Project ID \"$msg_id\" not found."
            return
        }
        set_variables_after_query
    } else {
        ad_return_complaint 1 "<li>Project ID \"$msg_id\" is invalid."
        return
    }
    if {[empty_string_p $ascopy]} {
        set is old
    } else { 
        set is ascopy
        set copy_project_id $project_id
        set what(ascopy) "New project as copy of $title_long"
        set title {}
        set title_long {}
        set description {}
    }
} else { 
    set is new
    set copy_project_id {}
    # ugh.
    set selection [ns_db select $db "select tp.* from ticket_projects tp where 0 = 1"]
    ns_db getrow $db $selection
    set_variables_after_query
    # defaults for new
    #HPMODE
    set code_set ad
    set public_p t
    if { [exists_and_not_null preset_default_mode] } {
	set default_mode $preset_default_mode
    } else {
	set default_mode full
    }
}

if {$is != "old"} { 
    # get a new project_id and stuff
    set selection [ns_db 1row $db "select 
            ticket_project_id_sequence.nextval as project_id,
            to_char(sysdate,'YYYY-MM-DD') as start_date,
            u.email, 
            u.first_names || ' ' || u.last_name as user_name
       from users u
       where user_id = $user_id"]
    set_variables_after_query
}

ReturnHeaders
set what(new) "Create Project"
set what(old) "Edit Project"

set submit(new) "Create"
set submit(ascopy) "Create Copy"
set submit(old) "Update"

lappend context [list {} $what($is)]

ns_write "[ad_header "Ticket: $what($is)"]
 <h1>Ticket: $what($is)</h1>
 [ticket_context $context]
<hr>"

if { ![exists_and_not_null title] } {
    set title $preset_title
}
if { ![exists_and_not_null title_long] } {
    set title_long $preset_title_long
}

ns_write "Project $title_long created by: $user_name (<a href=\"mailto:$email\">$email</a>)<br>
 <form action=\"$target\" method=post><table border=0>
 [export_form_vars project_id is return_url]"

ns_write "<tr><th align=left>Short Title:</th><td><input type=text name=title size=20 [export_form_value title]></td></tr>\n"

ns_write "<tr><th align=left>Long Title:</th><td><input type=text name=title_long size=60 [export_form_value title_long]></td></tr>\n"

ns_write "<tr><th align=left>Version:</th><td><input type=text name=version size=20 [export_form_value version]></td></tr>\n"

ns_write "<tr><th align=left>Start date:</th><td><input type=text name=start_date size=11 [export_form_value start_date]></td></tr>\n"

if {![empty_string_p $end_date]} {
    ns_write "<tr><th align=left>End date:</th><td>$end_date</td></tr>\n"
}
    

if { [empty_string_p $group_id] && [empty_string_p $owning_group_id] } {
    set setone {{{} {-- Set a group --}}}
} else { 
    set setone {}
}

# We would like to see the type of group because
# there could be many groups in the system, some
# with the same name.

# We define the type of group as:
# a) The name of the parent group if there is one
# b) The group_type otherwise

set select [ad_db_select_widget -default [util_decode $group_id "" $owning_group_id $group_id] -option_list $setone $db "select nvl(user_group_parent.group_name, user_groups.group_type) || ': ' || user_groups.group_name as group_name,  
user_groups.group_id 
from user_groups, user_groups user_group_parent
where user_groups.parent_group_id = user_group_parent.group_id (+)
and user_groups.approved_p = 't'
order by lower(nvl(user_group_parent.group_name, user_groups.group_type)), 
lower(group_name)
" group_id]

ns_write "<tr><th align=left>Owning Group:</th><td>$select</td></tr>\n"
ns_write "<tr><th align=left>Public?</th><td>"
if {$public_p != "f"} {
    ns_write "<input type=radio name=public_p value=t CHECKED> Yes
  <input type=radio name=public_p value=f> No</td>\n</tr>\n\n"
} else {  
    ns_write "<input type=radio name=public_p value=t> Yes
  <input type=radio name=public_p value=f CHECKED> No</td></tr>\n\n"
} 

ns_write "<tr><th valign=top align=left>Description:</th><td><textarea name=description rows=4 cols=60 wrap=hard>$description</textarea></td></tr>\n"

set select [ad_db_select_widget -default $code_set -option_list {{{} {*None*}}} $db "select distinct code_set, code_set from ticket_codes" code_set]
ns_write "<tr><th align=left>Code set:</th><td>$select</td></tr>\n"

set select [ad_db_select_widget -default $default_mode -option_list {{feedback Feedback} {full Full}} {} {} default_mode]
ns_write "<tr><th align=left>Default Mode:</th><td>$select</td></tr>\n"

if {$is != "old"} {
    set select [ad_db_select_widget -default $copy_project_id -option_list {{{} {--Optional--}}} $db "select title_long, project_id from ticket_projects tp where exists (select 1 from ticket_domain_project_map td where td.project_id = tp.project_id)" copy_project_id]
    ns_write "<tr><th align=left>Copy feature areas<br>from project:</th><td>$select</td></tr><tr><td align=center>or</td></tr>\n"
    set used_domains {}
} else {
    set used_domains [database_to_tcl_list $db "select domain_id from ticket_domain_project_map where project_id = $project_id"]
} 

set select [ad_db_select_widget -size 5 -multiple 1 -default $used_domains $db "select title_long, domain_id from ticket_domains" domain_id_list]
ns_write "<tr><th valign=top align=left>Assign<br>Feature areas:</th><td>$select</td></tr>\n"

ns_write "<tr><th valign=top align=left>New ticket<br>template:</th><td><textarea name=message_template
 rows=8 cols=60 wrap=hard>$message_template</textarea></td></tr>\n"


ns_write "</table> 
  <blockquote>
  <input type=submit value=\"$submit($is)\">
  </blockquote>
  </form>"
ns_write "[ad_footer]"

