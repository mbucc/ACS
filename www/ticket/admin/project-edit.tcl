# /www/ticket/admin/project-edit.tcl
ad_page_contract {
    Page to modify or create a ticket project.

    @param project_id the ID of the project being modified
    @param ascopy is this being created as a copy of an existing project
    @param ticket_return the URL of the ticket tracker
    @param return_url where to go back to when we are done
    @param owning_group_id the group reponsible for this project
    @param preset_title
    @param preset_title_long
    @param target where to go next

    @author Jeff Davis (davis@arsdigita.com) ?
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date ? 3.4 modifications 8 July 2000
    @cvs-id project-edit.tcl,v 3.6.2.7 2000/09/22 01:39:26 kevin Exp
} { 
    {project_id:integer {}} 
    {ascopy {}} 
    {ticket_return {/ticket/}}
    {return_url {/ticket/admin/index.tcl?}}
    {owning_group_id:integer {}} 
    {preset_title {}} 
    {preset_title_long {}} 
    {target {project-edit-2.tcl}}
}

# -----------------------------------------------------------------------------


set user_id [ad_verify_and_get_user_id]
set context [list \
                 [list $ticket_return "Ticket Tracker"] \
                 [list "$return_url&ticket_return=[ns_urlencode $ticket_return]" "Administration"]]

if { ![empty_string_p $project_id] } {
    # We are either modifying an old project or creating one copying
    # the values from another project to start with.
    
    page_validation {
	if { ![db_0or1row info_for_one_project "
	select tp.*,
	       u.email, 
	       u.first_names || ' ' || u.last_name as user_name, 
	       ug.group_name as orig_owning_group
	from   ticket_projects tp, 
	       users u, 
	       user_groups ug
	where  project_id = :project_id 
	and    u.user_id = tp.created_by 
	and    ug.group_id = tp.group_id" ] } {
    
             error "Project ID \"$msg_id\" not found."
        }
    }   

    if {[empty_string_p $ascopy]} {
	# We are modifying an existing project
        set is old
    } else { 
	# We are making a copy
        set is ascopy
        set copy_project_id $project_id
        set what(ascopy) "New project as copy of $title_long"
        set title {}
        set title_long {}
        set description {}
    }
} else { 
    # A completely new project
    set is new
    set copy_project_id {}
    set group_id ""
    set description ""
    set default_mode ""
    set version ""
    set message_template ""
    # defaults for new
    #HPMODE
    set code_set ad
    set public_p f
}

if {$is != "old"} { 
    # get a new project_id and stuff
    db_1row new_project_info "
    select ticket_project_id_sequence.nextval as project_id,
           to_char(sysdate,'YYYY-MM-DD') as start_date,
           u.email, 
           u.first_names || ' ' || u.last_name as user_name
    from   users u
    where  user_id = :user_id" 
    set created_by $user_id
}

set what(new) "Create Project"
set what(old) "Edit Project"

set submit(new) "Create"
set submit(ascopy) "Create Copy"
set submit(old) "Update"

lappend context [list {} $what($is)]

set page_content "
[ad_header "Ticket: $what($is)"]

<h2>Ticket: $what($is)</h2>

[ticket_context $context]

<hr>"

if { ![exists_and_not_null title] } {
    set title $preset_title
}
if { ![exists_and_not_null title_long] } {
    set title_long $preset_title_long
}

append page_content "
<blockquote>
<h3>Project: $title_long</h3>
 created by: [ticket_user_display $user_name $email $created_by admin]<br>"

if {[info exists orig_owning_group]} { 
    append page_content "Owning group: <a href=\"/admin/ug/group?group_id=$group_id\">$orig_owning_group</a> &nbsp;(<a href=\"project-change-group?project_id=$project_id&project_name=[ns_urlencode $title_long]\">change</a>)"  
}

append page_content "
<form action=\"$target\" method=post>
 [export_form_vars project_id is return_url]

<table border=0>

  <tr>
    <th align=left>Short Title:</th>
    <td><input type=text name=title size=20 [export_form_value title]></td>
  </tr>

  <tr>
    <th align=left>Long Title:</th>
    <td><input type=text name=title_long size=60 [export_form_value title_long]></td>
  </tr>

  <tr>
    <th align=left>Version:</th>
    <td><input type=text name=version size=20 [export_form_value version]></td>
  </tr>

  <tr>
    <th align=left>Start date:</th>
    <td><input type=text name=start_date size=11 [export_form_value start_date]></td>
  </tr>
"

if {[exists_and_not_null end_date]} {
    append page_content "  <tr>
    <th align=left>End date:</th>
    <td>$end_date</td>
  </tr>\n"
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

set select [ad_db_select_widget \
	-default [util_decode $group_id "" $owning_group_id $group_id] \
	-option_list $setone ticket_group_info "
select nvl(user_group_parent.group_name, user_groups.group_type) || ': ' || user_groups.group_name as group_name,  
      user_groups.group_id 
from  user_groups, 
      user_groups user_group_parent
where user_groups.parent_group_id = user_group_parent.group_id (+)
and   user_groups.approved_p = 't'
order by lower(nvl(user_group_parent.group_name, user_groups.group_type)), 
         lower(group_name)
" group_id]

append page_content "
  <tr>
    <th align=left>Owning Group:</th>
    <td>$select</td>
  </tr>

[bool_table_prompt -span 2 {Tickets publicly visible?} public_p $public_p]

  <tr>
    <th valign=top align=left>Description:</th>
    <td><textarea name=description rows=4 cols=60 wrap=hard>$description</textarea></td>
  </tr>
"

set select [ad_db_select_widget -default $code_set \
	-option_list {{{} {*None*}}} "ticket_all_code_sets"  \
	"select distinct code_set, code_set from ticket_codes" code_set]

append page_content "
  <tr>
    <th align=left>Code set:</th>
    <td>$select</td>
  </tr>
"

set select [ad_db_select_widget -default $default_mode -option_list {{feedback Feedback} {full Full}} {} {} default_mode]

append page_content "
  <tr>
    <th align=left>Default Mode:</th>
    <td>$select</td>
  </tr>"

if {$is != "old"} {
    set select [ad_db_select_widget -default $copy_project_id \
	    -option_list {{{} {--Optional--}}} "ticket_titles" \
	    "select title_long, project_id from ticket_projects tp where exists (select 1 from ticket_domain_project_map td where td.project_id = tp.project_id)" copy_project_id]

    append page_content "
  <tr>
    <th align=left>Copy feature areas<br>from project:</th>
    <td>$select</td>
  </tr>
  <tr>
    <td align=center>or</td>
  </tr>\n"
    set used_domains {}
} else {
    set used_domains [db_list domains_for_one_project "
    select domain_id 
    from   ticket_domain_project_map 
    where  project_id = :project_id"]
} 

set select [ad_db_select_widget -size 5 -multiple 1 -default $used_domains \
	"get titles" "select title_long, domain_id from ticket_domains" domain_id_list]

append page_content "
  <tr>
    <th valign=top align=left>Assign<br>Feature areas:</th>
    <td>$select</td>
  </tr>

  <tr>
    <th valign=top align=left>New ticket<br>template:</th>
    <td><textarea name=message_template rows=8 cols=60 wrap=hard>
        $message_template</textarea></td>
  </tr>

</table> 

<blockquote>
  <input type=submit value=\"$submit($is)\">
</blockquote>

</blockquote>
</form>

[ad_footer]"



doc_return  200 text/html $page_content
