# $Id: index.tcl,v 3.1 2000/02/20 21:21:56 davis Exp $
ad_page_variables {
    {domain_id {}}
    {project_id {}}
    {orderby {title}}
    {view projects}
    {ticket_return {/ticket/}}
    {updmsg {}}
}

set dbl [ns_db gethandle main 2 ]
set db [lindex $dbl 0]
set db2 [lindex $dbl 1]
set user_id [ad_get_user_id]

set sql_restrict {}
set context [list \
                 [list $ticket_return "Ticket Tracker"] \
                 [list "[ns_conn url]?[export_url_vars ticket_return]" "Administration"]]

set return_url "&[export_url_vars ticket_return]&return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars]"]"

switch $view { 

    projects { 
        # All projects 
        set update_assignments 0
        set page_title "All Projects"
        lappend context [list {}  "All Projects"]
        set dimensional {
            {projectstate "Project State" open {
                {open "open" {where "(tp.end_date > sysdate or tp.end_date is null)"}}
                {closed "closed" {where "tp.end_date < sysdate"}}
                {all "all" {}}
            }}
            {public "Public" all {
                {yes "yes" {where "public_p = 't'"}}
                {no "no"  {where "public_p = 'f'"}}
                {all "all"  {}}
            }}
        }
        
        set table_def {
            {title "Project" {upper(tp.title) $order} {}}
            {version "Version" {} {}}
            {group_name "Group" {} 
                {<td><a href="[ns_conn location]/admin/ug/group.tcl?group_id=$group_id">$group_name</a></td>}
            }
            {code_set "Codes" {} {}}
            {domains "Feature Areas" {} {}}
            {default_mode "Entry mode" {} {}}
            {ended "State" {ended [ad_reverse $order]} {<td>[if {$ended > 0} {
                subst {open}
            } else { 
                subst {closed}
            }]</td>}}
            {public_p "Public?" {public_p [ad_reverse $order]} tf}
            {actions "Actions" no_sort 
                {<td><a href="index.tcl?view=project&project_id=$project_id&[export_ns_set_vars url {view project_id domain_id}]">view feature areas</a>
                    | <a href="project-edit.tcl?project_id=$project_id[uplevel set return_url]">edit</a>
                    | <a href="project-edit.tcl?project_id=$project_id&ascopy=1[uplevel set return_url]">copy project</a>
                    [if {$ended > 0} { 
                        subst {| <a href="project-close.tcl?project_id=$project_id[uplevel set return_url]">close</a>}
                    } else { 
                        subst {| <a href="project-close.tcl?project_id=$project_id&reopen=1[uplevel set return_url]">reopen</a>}
                    }]
                    </td> }}
        }

        set query "
   select 
     tp.title,
     tp.project_id,
     tp.version, 
     tp.code_set,
     tp.public_p,
     tp.default_mode,
     ug.group_name,
     ug.group_id,
     nvl(map.domains,0) as domains,
     nvl(trunc(end_date - sysdate),10000) as ended
   from ticket_projects tp, user_groups ug,
     (select project_id, count(*) as domains from ticket_domain_project_map tgm group by project_id) map
   where tp.group_id = ug.group_id(+)
    and map.project_id(+) = tp.project_id
   [ad_dimensional_sql $dimensional where]
   [ad_order_by_from_sort_spec $orderby $table_def]\n"
    }


    domain { 
        # Projects for a domain
        set update_assignments 1
        set selection [ns_db 0or1row $db "select title as domain_title, title_long as domain_title_long from ticket_domains where domain_id = $domain_id"]
        if {![empty_string_p $selection]} { 
            set_variables_after_query
            if { [string compare $domain_title_long $domain_title] == 0} {
                set page_title "Feature Area: <strong>$domain_title</strong>"
            } else { 
                set page_title "Feature Area: <strong>$domain_title - $domain_title_long</strong>"
            }
            lappend context [list {}  "One feature area"]
        } else { 
            ad_return_comlaint 1 "<li>Invalid domain ID \"$domain_id\"."
            return
        }
            
        set dimensional {
           {projects "Project State" open {
                {open "open" {where "(tp.end_date > sysdate or tp.end_date is null)"}}
                {closed "closed" {where "tp.end_date < sysdate"}}
                {all "all" {}}
            }}
            {public "Public" all {
                {yes "yes" {where "public_p = 't'"}}
                {no "no"  {where "public_p = 'f'"}}
                {all "all"  {}}
            }}
        }
        
        set table_def {
            {title "Project" {upper(tp.title) $order} {}}
            {version "Version" {} {}}
            {group_name "Group" {} 
                {<td><a href="[ns_conn location]/admin/ug/group.tcl?group_id=$group_id">$group_name</a></td>}
            }
            {code_set "Codes" {} {}}
            {domains "Feature Areas" {} r}
            {ended "State" {ended [ad_reverse $order]} {<td>[if {$ended > 0} {
                subst {open}
            } else { 
                subst {closed}
            }]</td>}}
            {public_p "Public?" {public_p [ad_reverse $order]} tf}
            {email "Default Assignee" {upper(u.last_name) $order, upper(u.first_names) $order}
                {<td>[ticket_assignee_select [uplevel set db2] $project_id $domain_id $group_id $user_id]</td>}}
            {actions "Actions" no_sort 
                {<td><a href="index.tcl?view=project&project_id=$project_id&[export_ns_set_vars url {view project_id domain_id}]">view feature areas</a>
                    | <a href="project-edit.tcl?project_id=$project_id[uplevel set return_url]">edit</a>
                    | <a href="project-edit.tcl?project_id=$project_id&ascopy=1[uplevel set return_url]">copy project</a>
                    [if {$ended > 0} { 
                        subst {| <a href="project-close.tcl?project_id=$project_id[uplevel set return_url]">close</a>}
                    } else { 
                        subst {| <a href="project-close.tcl?project_id=$project_id&reopen=1[uplevel set return_url]">reopen</a>}
                    }]
                    </td> }}
        }
        set query "
   select 
     tp.title,
     tp.project_id,
     tp.version, 
     tp.code_set,
     tp.public_p,
     ug.group_name,
     ug.group_id,
     u.user_id,
     u.email, 
     u.first_names, 
     u.last_name,
     tgm.domain_id,
     nvl(map.domains,0) as domains,
     nvl(trunc(tp.end_date - sysdate),10000) as ended
   from ticket_projects tp, user_groups ug,
     (select project_id, count(*) as domains from ticket_domain_project_map tgm group by project_id) map, 
     ticket_domain_project_map tgm, users u, ticket_domains td
   where td.group_id = ug.group_id(+)
    and map.project_id(+) = tp.project_id
    and tgm.project_id = tp.project_id 
    and tgm.domain_id = $domain_id
    and td.domain_id = tgm.domain_id
    and tgm.default_assignee = u.user_id(+)
   [ad_dimensional_sql $dimensional where]
   [ad_order_by_from_sort_spec $orderby $table_def]\n"
    }



    domains { 
        # list of all domains 
        set page_title "All Feature Areas"
        set update_assignments 0
        lappend context [list {}  "All Feature Areas"]
        set dimensional {
            {default_assignee "Default Assignee" all {
                {yes "exists" {where "td.default_assignee is not null"}}
                {no "absent" {where "td.default_assignee is null"}}
                {all "all"  {}}
            }}
            {public "Public" all {
                {yes "yes" {where "public_p = 't'"}}
                {no "no"  {where "public_p = 'f'"}}
                {all "all"  {}}
            }}
        }
        
        set table_def {
            {title "Feature Area" {upper(td.title) $order} {}}
            {group_name "Group" {upper(group_name) $order} 
                {<td><a href="[ns_conn location]/admin/ug/group.tcl?group_id=$group_id">$group_name</a></td>}
            }
            {projects "Projects" {} r}
            {public_p "Public?" {} tf}
            {actions "Actions" no_sort 

                {<td><a href="index.tcl?view=domain&domain_id=$domain_id&[export_ns_set_vars url {view domain_id project_id}]">view projects</a>
                     
                    | <a href="domain-edit.tcl?domain_id=$domain_id[uplevel set return_url]">edit</a>
                    | <a href="domain-edit.tcl?domain_id=$domain_id&ascopy=1[uplevel set return_url]">copy feature area</a>
                </td>}}
        }

        set query "
   select 
     td.title,
     td.domain_id,
     td.public_p,
     ug.group_name,
     ug.group_id,
     nvl(map.projects, 0) as projects
   from ticket_domains td, user_groups ug, 
     (select domain_id, count(*) as projects from ticket_domain_project_map group by domain_id) map
   where td.group_id = ug.group_id(+)
    and map.domain_id(+) = td.domain_id $sql_restrict
   [ad_dimensional_sql $dimensional where]
   [ad_order_by_from_sort_spec $orderby $table_def]\n"
    }



    project { 
        # domains for a particular project 
        set update_assignments 1
        set selection [ns_db 0or1row $db "select title as project_title, title_long as project_title_long from ticket_projects where project_id = $project_id"]
        if {![empty_string_p $selection]} { 
            set_variables_after_query
        } else { 
            ad_return_comlaint 1 "<li>Invalid project ID \"$project_id\"."
            return
        }

        if { [string compare $project_title_long $project_title] == 0} {
            set page_title "Project: <strong>$project_title</strong>"
        } else { 
            set page_title "Project: <strong>$project_title - $project_title_long</strong>"
        }
        lappend context [list {} "One project"]
        set dimensional {
            {default_assignee "Default Assignee" all {
                {yes "exists" {where "tgm.default_assignee is not null"}}
                {no "absent" {where "tgm.default_assignee is null"}}
                {all "all"  {}}
            }}
            {public "Public" all {
                {yes "yes" {where "td.public_p = 't'"}}
                {no "no"  {where "td.public_p = 'f'"}}
                {all "all"  {}}
            }}
        }
        
        set table_def {
            {title "Feature Area" {upper(td.title) $order} {}}
            {group_name "Group" {upper(group_name) $order} 
                {<td><a href="[ns_conn location]/admin/ug/group.tcl?group_id=$group_id">$group_name</a></td>}
            }
            {projects "Projects" {} r}
            {public_p "Public?" {} tf}
            {email "Default Assignee" {upper(u.last_name) $order, upper(u.first_names) $order}
                {<td>[ticket_assignee_select [uplevel set db2] $project_id $domain_id $group_id $user_id]</td>}}
            {actions "Actions" no_sort 
                {<td><a href="index.tcl?view=domain&domain_id=$domain_id&[export_ns_set_vars url {view domain_id project_id}]">view projects</a>
                    | <a href="domain-edit.tcl?domain_id=$domain_id[uplevel set return_url]">edit</a>
                    | <a href="domain-edit.tcl?domain_id=$domain_id&ascopy=1[uplevel set return_url]">copy feature area</a>
                    | <a href="domain-remove.tcl?project_id=[uplevel set project_id]&domain_id=$domain_id[uplevel set return_url]">remove</a>
                </td>}}
        }

        set query "
   select 
     td.title,
     td.domain_id,
     td.public_p,
     $project_id as project_id,
     ug.group_name,
     ug.group_id,
     u.email, 
     u.user_id,
     td.group_id,
     u.first_names, 
     u.last_name,
     nvl(map.projects, 0) as projects
   from ticket_domains td, user_groups ug, 
     (select domain_id, count(*) as projects from ticket_domain_project_map group by domain_id) map,
     ticket_domain_project_map tgm, users u
   where td.group_id = ug.group_id(+)
    and map.domain_id(+) = td.domain_id $sql_restrict
    and tgm.project_id = $project_id
    and tgm.domain_id = td.domain_id
    and tgm.default_assignee = u.user_id(+)
   [ad_dimensional_sql $dimensional where]
   [ad_order_by_from_sort_spec $orderby $table_def]\n"
    }
}


ReturnHeaders

ns_write "[ad_header "[ticket_system_name] Administration"]
 <h2>[ticket_system_name] - $page_title</h2>
 [ticket_context $context]
 <hr>\n"

ns_write "<table width=100%>
    <tr>
      <td>
         View:
            <a href=\"index.tcl?view=projects&[export_ns_set_vars url {view project_id domain_id}]\">All Projects</a>
          | <a href=\"index.tcl?view=domains&[export_ns_set_vars url {view domain_id project_id}]\">All Feature Areas</a>
      </td>
      <td valign=top align=right>[ticket_feedback_link]&nbsp;|&nbsp;<a href=\"help.html\">Help</a></td>
    </tr>
    </table>
          Create new: <a href=\"project-edit.tcl\">Project</a> 
          | <a href=\"domain-edit.tcl\">Feature Area</a>"



ns_write "[ad_dimensional $dimensional]<br>"
set selection [ns_db select $db $query] 
if { $update_assignments } { 
    ns_write "<form method=GET action=\"ticket-assignments-update.tcl\">\n"
}
ns_write "[ad_table -Torderby $orderby $db $selection $table_def]\n"
if { $update_assignments } { 
    ns_write "<input type=hidden name=return_url value=\"[philg_quote_double_quotes "[ns_conn url]?[export_ns_set_vars url]"]\">
   <blockquote>
   <input type=submit value=\"Update Assignments\">
   </blockquote>
   </form>"
}

ns_write "[ad_footer]"

