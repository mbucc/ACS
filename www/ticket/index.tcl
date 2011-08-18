# $Id: index.tcl,v 3.7 2000/03/08 13:13:45 davis Exp $
# Top level page for the ticket tracker v3.x

# still a little embarassing since it is so modal...


# Retain ns_writes here since otherwise if you as for a huge bunch of
# tickets (like all of them) you have to wait for the query to finish
# and the table to be built.  Much better to pop top of page out 
# quickly.
 
# The table itself is returned atomically so you do not have an active 
# query waiting for a consumer.


set db [ns_db gethandle]
set user_id [ad_get_user_id]

set debug {}

# Load the persistent page defaults
ad_custom_page_defaults [ad_custom_load $db $user_id ticket_settings [ns_conn url] slider_custom]

ad_page_variables {
    {expert 1}
    {customize {}} 
    {view {}}
    {ticket_table {}} 
    {ticket_sort {}} 
    {orderby {}}
    {default_orderby {msg_id*}}
    {project_id {}}
    {domain_id -multiple-list}
    {advs 0}
    {advs_results 0}
    {qs 0}
    {query_string {}}
    {debug -multiple-list}
}

if {![empty_string_p $project_id] } {
    set selection [ns_db 0or1row $db "
 select title_long as project_title_long, code_set, 
   group_id as project_group_id 
 from ticket_projects  
 where project_id = $project_id"]

    if {[empty_string_p $selection]} { 
        ad_return_complaint 1 "<li>Invalid project id\n"
        return
    }
    set_variables_after_query
}

if { ! [info exists domain_id] || [lsearch $domain_id {all}] > -1 }  {
    set domain_id {}
}


# sorting state a little tricky since we want 
# to default but we also want ticket_sort not to be overriden 
# by the defaulting...
if {[empty_string_p $orderby] 
    && [empty_string_p $ticket_sort]} { 
    set orderby $default_orderby
}

# this is only for the settings screen...
set orderby_list {
    {{msg_id*} "ID#"}
    {priority "Priority"}
    {ticket_type "Ticket Type"}
    {created "Submitter"}
    {status "Status"}
    {severity "Severity"}
    {creation_mdy "Creation Date"}
    {assigned_user_email "Assignee" }
    {project_title "Project"}
    {domain_title "Feature area"}
    {modification_mdy "Date Modified"}
    {close_mdy "Date Closed"}
}

set return_url "return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url [list ticket_settings customize]]"]"
set admin_return "ticket_return=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url [list ticket_settings customize]]"]"
set state_noproj "[ns_conn url]?[export_ns_set_vars url [list project_id customize ticket_settings]]"
set state_nodom "[ns_conn url]?[export_ns_set_vars url [list domain_id customize ticket_settings]]"
set state_nodompro "[ns_conn url]?[export_ns_set_vars url [list domain_id customize project_id ticket_settings]]"


#
# Generate context bar.
#

set sql_restrict {} 
set page_title {}
set remove_column [list]


if {![empty_string_p $customize]} { 
    # Customizing (tables, sorts, settings)

    # do not lose context when customizing
    set context [list [list "[ns_conn url]?[export_ns_set_vars url [list customize]]" {Ticket Tracker}]]
    switch $customize { 
        settings { 
            lappend context [list {} {Individual Settings}]
        } 
        table { 
            lappend context [list {} {Customize Table View}]
        } 
        sort { 
            lappend context [list {} {Customize Sorts}]
        }
    }
} elseif { $advs && ! $advs_results } { 

    # defining an advanced search

    set context [list [list "[ns_conn url]?[export_ns_set_vars url [list advs advs_results]]" {Ticket Tracker}]]

    lappend context [list {} {Specify Advanced Search}]

    append page_title ": Specify Advanced Search"
    
} else { 
    # normal display of results

    set context [list [list "[ns_conn url]?domain_id=all&project_id=&[export_ns_set_vars url [list project_id domain_id customize view qs advs advs_results]]" {Ticket Tracker}]]

    if {($qs && ![empty_string_p $query_string])
        || ($advs && $advs_results) } { 
        # rows are result of a search 

        lappend context [list "[ns_conn url]?domain_id=all&project_id=&[export_ns_set_vars url [list project_id domain_id customize view]]" "Search Results"]

        if { $qs } { 
            append page_title ": Search \"[string trim $query_string]\""
        } else { 
            append page_title ": Advanced Search"
        }
    }
    
    if {![empty_string_p $project_id]} { 
        append sql_restrict "and ti.project_id = $project_id"

        lappend context [list "[ns_conn url]?domain_id=all&[export_ns_set_vars url [list customize view domain_id]]" "One Project"]    
        append page_title ": Project - $project_title_long"
        lappend remove_column project_title
    }
    
    if {![empty_string_p $domain_id] } {
	if { [llength $domain_id] > 1 } {
	    set domain_title_long "Multiple"
            lappend context  [list "[ns_conn url]?view=&[export_ns_set_vars url [list customize view]]" "Multiple Feature Areas"]
	} else {
	    set selection [ns_db 0or1row $db "select
        title_long as domain_title_long, group_id as domain_group_id 
      from ticket_domains  
      where domain_id = $domain_id"]
	    if {[empty_string_p $selection]} { 
		ad_return_complaint 1 "<li>Invalid domain id\n"
		return
	    }
	    set_variables_after_query
            lappend context  [list "[ns_conn url]?view=&[export_ns_set_vars url [list customize view]]" "One Feature Area"]
            lappend remove_column domain_title
	}
        append sql_restrict " and ti.domain_id in ([join  $domain_id {,}])"
        append page_title ": Feature Area - $domain_title_long"
    }

    if {$view == "report"} { 
        lappend context [list {} "Summary Report"]
    } elseif {$view == "full_report" } { 
        lappend context [list {} "Full Report"]
    }
    
    if {[empty_string_p $page_title]} { 
        set page_title " -  All Projects"
    }
}


ReturnHeaders

ns_write "[ad_header "[ticket_system_name] $page_title"]
 <h3>[ticket_system_name] $page_title</h3>
 [ticket_context $context]    
 <hr>\n"


# 
# Dimensional slider definitions
#

set dimensional {
    {submitby "Submitted&nbsp;by" any {
        {mine "me" {where "users.user_id = $user_id"}}
        {any "anyone"}
    }}
    {assign "Ticket&nbsp;Assignment" mine {
        {mine "mine" {
            where "(exists (
               select msg_id from ticket_issue_assignments 
               where ticket_issue_assignments.msg_id = ti.msg_id
               and ticket_issue_assignments.user_id = $user_id))"}}
        {any "everyone's" {}}
        {noass "unassigned" {where "(active_p = 'f' or active_p is null) "}}    }}
    {status "Status" active {
        {active "open" {where "(status_class = 'active' or status_class is null)"}}
        {deferred "deferred" {where "status_class  = 'defer'"}}
        {closed "closed" {where "status_class  = 'closed'"}}
        {any "all" {}}
    }}
    {created "Creation Time" any {
        {1d "last 24hrs" {where "posting_time + 1 > sysdate"}}
        {1w "last week" {where "posting_time + 7 > sysdate"}}
        {1m "last month" {where "posting_time + 30 > sysdate"}}
        {any "all" {}}
    }}
}

#
# Table Column Definitions
#

set table_def {
    {line_number "Num" no_sort {<td align=right>$Tcount</td>}}
    {score "Score" {} r}
    {msg_id "ID#" {ti.msg_id $order} 
        {<td align=right><a href="/ticket/issue-view.tcl?msg_id=$msg_id&mode=full&[uplevel set return_url]">$msg_id</a></td>}
    }
    {priority "Pri" {priority_seq $order} {<td>$priority</td>}}
    {ticket_type "Type" {ticket_type_seq $order} {<td>[string range $ticket_type 0 3]</td>}}
    {created "Submitted&nbsp;by" 
        {upper(users.last_name) $order, upper(users.first_names) $order} 
        {<td>[ticket_user_display $user_name $email $user_id]</td>}
    }
    {status "Status" {status_seq $order}
    {<td>[switch $status_subclass {
        "approve" {subst {<font color=green>$status</font>}}
        "clarify" {subst {<font color=red>$status</font>}}
        default {subst $status}}]</td>}
    }
    {severity "Sever" {severity_seq $order} {}}
    {creation_mdy "Created" {posting_time $order} {}}
    {deadline_mdy "Deadline" 
        {ti.deadline $order} 
        {[if {$pastdue_days >= 0 && $status_class == "active"} {
                subst "<td><font color=red>$deadline_mdy</font></td>"
            } else {
                if {[empty_string_p $deadline_mdy]} { 
                    subst "<td>&nbsp</td>"
                } else {
                    subst "<td>$deadline_mdy</td>"
                }
            }]
        }
    }
    {assigned_user_email "Assigned&nbsp;to" 
        {upper(assigned_users.last_name) $order, upper(assigned_users.first_names) $order}
        {
            [switch $assigned_user_name {
                "&nbsp;" {
                    if {$status_class == "active"} { 
                        subst {<td><font color=red>unassigned</font></td>}
                    } else {
                        subst {<td>&nbsp;</td>}
                    }
                }
                default {
                    subst {<td>[ticket_user_display $assigned_user_name $assigned_user_email $assigned_user_id]</td>}
                }
            }]
        }
    }
    {one_line "Subject" {upper(ti.one_line) $order} {}}
    {project_title "Project" {} 
        {<td><a href="[uplevel set state_noproj]&project_id=$project_id">$project_title</a>}}
    {domain_title "Feature&nbsp;area" {} 
        {<td><a href="[uplevel set state_nodom]&domain_id=$domain_id">$domain_title</a>}}
    {modification_mdy "Modified" {} {}}
    {close_mdy "Closed" {} {}}
    {public_p "Public?" {} tf}
    {notify_p "Notify?" {} tf}
    {version "Ver\#" {} {}}
    {actions "Actions" no_sort
        {<td>[ticket_actions $msg_id $status_class $status_subclass $responsibility [uplevel set user_id] $user_id $assigned_user_id [uplevel set return_url] index]</td>}
    }
}


#
# Load user customized stuff 
#


set col {}
if {$expert} { 
    if {![empty_string_p $ticket_table]} { 
        set col [ad_custom_load $db $user_id ticket_table $ticket_table table_view]
    }

    if {[empty_string_p $orderby]} {
        if { ![empty_string_p $ticket_sort]} { 
            set orderby [ad_custom_load $db $user_id ticket_sort $ticket_sort table_sort]
        }
    } else { 
        set ticket_sort {}
    }
}

if {[empty_string_p $col]} {
    if {($qs || $advs) && ![empty_string_p $query_string]} { 
        set col {
        line_number score msg_id priority ticket_type 
        created status severity creation_mdy deadline_mdy
        assigned_user_email one_line project_title domain_title 
        }
    } else { 
        set col {
        line_number msg_id priority ticket_type 
        created status severity creation_mdy deadline_mdy 
        assigned_user_email one_line project_title domain_title 
        }
    }
} 


#
# The ugly query...
#
if { $advs } { 
    set tmp [ticket_build_advs_query]
    if {! [empty_string_p $tmp ] } { 
        append sql_restrict { and } $tmp
    }
} else { 
    append sql_restrict [ad_dimensional_sql $dimensional where]
}

if {($qs || $advs) && ![empty_string_p $query_string]} {
    regsub -all { *,+ *} [string trim $query_string] { } search
    set numsearch {}
    if { ! $advs } { 
        regsub -all {[^0-9]+} $search { } numsearch 
        set numsearch [join [collapse [split $numsearch {, }] {^[0-9][0-9][0-9]+$}] {,}]
        if {![empty_string_p $numsearch]} { 
            set numsearch " or on_what_id in ($numsearch)"
        } else { 
            set numsearch {}
        }
    }
    util_dbq search
    set psc "pseudo_contains(dbms_lob.substr(content,3000) || u.email || u.first_names || u.last_name || one_line, $DBQsearch)"
    set search_from ",(select on_what_id, sum($psc) as score from users u, general_comments gc where gc.user_id = u.user_id and ($psc > 0 $numsearch) and on_which_table in('ticket_issues_i','ticket_issues') group by on_what_id) psc"
    set search_columns ", psc.score"
    set search_term " and psc.on_what_id = ti.msg_id"
} else { 
    set search_columns ", 0 as score"
    set search_from {}
    set search_term {}
}

set query "select 
   ti.*, 
   gc.content as message,
   users.email,
   users.user_id,
   users.first_names || '&nbsp;' || users.last_name as user_name,
   ticket_projects.project_id,
   ticket_projects.title as project_title,
   ticket_projects.title_long as project_title_long,
   ticket_projects.version,
   ticket_domains.title as domain_title,
   ticket_domains.title_long as domain_title_long,
   ticket_domains.group_id as domain_group_id,
   ta.user_id as assigned_user_id,
   assigned_users.first_names || '&nbsp;' || assigned_users.last_name 
     as assigned_user_name,
   assigned_users.email as assigned_user_email,
   closing_users.first_names || '&nbsp;' || closing_users.last_name
     as closing_user_name,
   closing_users.email as closing_user_email $search_columns
 from ticket_issues ti, 
   ticket_viewable tv, 
   ticket_projects, 
   ticket_domains, 
   users, 
   users assigned_users,
   users closing_users, 
   ticket_issue_assignments ta, 
   general_comments gc $search_from
 where tv.msg_id = ti.msg_id and tv.user_id = $user_id
   and users.user_id = ti.user_id 
   and ticket_projects.project_id = ti.project_id 
   and ticket_domains.domain_id = ti.domain_id 
   and ti.msg_id = ta.msg_id(+)
   and ta.user_id = assigned_users.user_id(+) 
   and ti.closed_by = closing_users.user_id(+) 
   and gc.comment_id(+) = ti.comment_id
   $sql_restrict $search_term  [ad_order_by_from_sort_spec $orderby $table_def]\n"

#
#  Special table breaking code for certain sorts.
#


set rowcode {}
switch [ad_sort_primary_key $orderby] { 
    created {
        lappend remove_column created
        set rowcode {
            [if {![ad_table_same user_id]} {
                ad_table_span [subst {Submitted by: [ticket_user_display $user_name $email $user_id]}] "bgcolor=cccccc"
            }]
        }
    }
    assigned_user_email {
        lappend remove_column assigned_user_email
        set rowcode {
            [if {![ad_table_same assigned_user_id]} {
                ad_table_span [switch $assigned_user_name {
                    "&nbsp;" {subst {<font color=red>unassigned</font>}}
                    default {subst {Assigned to: [ticket_user_display $assigned_user_name $assigned_user_email $assigned_user_id] }}
                }] "bgcolor=cccccc"
            }
            ]}
    }

    project_title {
        lappend remove_column project_title
        if {[empty_string_p $project_id]} { 
            set rowcode {
                [if {![ad_table_same project_id]} {
                    ad_table_span [subst {<strong>$project_title_long</strong> (<a href="[uplevel set state_noproj]&project_id=$project_id">view this project only</a>)}] "bgcolor=cccccc"
                }]
            }
        } else { 
            set rowcode {}
        }
    }
    domain_title {
        lappend remove_column domain_title
        if {[empty_string_p $domain_id]} { 
            set rowcode {
                [if {![ad_table_same domain_id]} {
                    ad_table_span [subst {<strong>$domain_title_long</strong> (<a href="[uplevel set state_nodom]&domain_id=$domain_id">view this feature area only</a>)}] "bgcolor=cccccc"
                }]
            }
        }
    }
}

#
# generate the columns we really want to see given the list of removes
#
set all_columns $col
set col [list]
foreach acol $all_columns { 
    if {[lsearch -exact $remove_column $acol] < 0} { 
        lappend col $acol
    }
}

if { $customize == "settings" } {
    # customizing page defaults -- nuke from environment anything we will set on the 
    # settings screen.
    set return_url "[ns_conn url]?[export_ns_set_vars url [list ticket_table customize submitby assign status created project_id domain_id expert orderby]]"
    ns_write "[ad_custom_form $return_url ticket_settings [ns_conn url]]"
    ns_write "<table>\n[ad_dimensional_settings $dimensional [ns_getform]]"
    ns_write "<tr><th align=left>Default project</th><td>
       [ad_db_select_widget -default $project_id -option_list {{{} {-- All Projects --}}} $db "select
          title_long, project_id 
          from ticket_projects
          where end_date is null or end_date > sysdate 
          order by UPPER(title_long) asc" project_id]</td></tr>"
    ns_write "<tr><th align=left>feature area</th><td>
      [ad_db_select_widget -default $domain_id -option_list {{{all} {-- All Feature areas --}}} $db "select distinct td.title_long, td.domain_id 
          from ticket_domains td, ticket_domain_project_map tgm , ticket_projects tp where td.domain_id = tgm.domain_id and tgm.project_id = tp.project_id and (tp.end_date is null or tp.end_date > sysdate) and (td.end_date is null or td.end_date > sysdate)
          order by UPPER(td.title_long) asc" domain_id]</td></tr>"
    ns_write "<tr><th align=left>Default sort </th><td><select name=default_orderby>[html_select_value_options $orderby_list $orderby]</select></td></tr>"
    ns_write "<tr><th align=left>Ticket tracker mode</th><td><select name=expert>[html_select_value_options {{0 {Normal}} {1 {Expert}}} $expert]</select></td></tr>"
    ns_write "</table></form>"
} elseif { $customize == "table" } { 
    # If we are in table customization mode.
    set return_url "[ns_conn url]?[export_ns_set_vars url [list ticket_table customize]]"
    ns_write "[ad_table_form $table_def select $return_url ticket_table $ticket_table $col]"
} elseif { $customize == "sort" } {
    # If we are in sort customization mode.
    set return_url "[ns_conn url]?[export_ns_set_vars url [list orderby customize ticket_sort]]"
    ns_write "[ad_table_sort_form $table_def select $return_url ticket_sort $ticket_sort $orderby]"
} elseif { $view == "report" || $view == "full_report"} {
    # make a report out of it all.
    
    set selection [ns_db select $db $query] 
    ns_write "[ticket_report $db $selection $view $table_def]<p>"
} else { 
    set admin_p [ticket_user_admin_p $db]

    # otherwise spit out some results.

    # the top nav bar
    ns_write "<table width=100% CELLPADDING=0 CELLSPACING=0><tr>
  <td>Add&nbsp;new:&nbsp;<a href=\"issue-new.tcl?$return_url\">ticket</a>"
    if { ![empty_string_p $project_id]} { 
        ns_write " | <a href=\"issue-new.tcl?[export_url_vars project_id]&$return_url\">ticket in $project_title_long</a>"
    }
    ns_write "</td><td valign=top align=right>\[&nbsp;"
    if { $admin_p } { 
        ns_write "<a href=\"/ticket/admin/index.tcl?$admin_return\">Project&nbsp;Administration</a>&nbsp|&nbsp;"
    }
    ns_write "<a href=\"[ns_conn url]?[export_ns_set_vars url [list orderby customize]]&customize=settings\">Custom Settings</a>&nbsp;|&nbsp;<a href=\"help.adp\">Help</a>&nbsp;\]</td></tr>"


    # the upleasant loserish UI at the bottom
    ns_write "<tr><td colspan=2>Summarize by: <a href=\"project-summary.tcl?return_url=[ns_urlencode $state_nodompro]\">project</a> 
       | <a href=\"domain-summary.tcl?return_url=[ns_urlencode $state_nodompro]\">feature area</a> 
       | <a href=\"user-summary.tcl?return_url=[ns_urlencode $state_nodompro]\">submitting user</a> 
       | <a href=\"user-assign-summary.tcl?return_url=[ns_urlencode $state_nodompro]\">assigned user</a></td></tr>"

       

    # The change project select 
    if { $advs && ! $advs_results } {
        # if we are not displaying adv search results 
        ns_write "</table>"
    } else { 
        ns_write "<tr><td colspan=2>View/Print: <a href=\"[ns_conn url]?view=full_report&[export_ns_set_vars url [list customize view]]\">Full Report (with comments)</a>
       | <a href=\"[ns_conn url]?view=report&[export_ns_set_vars url [list customize view]]\">Summary Report (no comments)</a></td></tr></table>"

        ns_write "<form method=GET action=\"index.tcl\">View project:
      [ad_db_select_widget -default $project_id -option_list {{{} {-- All Projects --}}} $db "select title_long, project_id 
        from ticket_projects tp where 
          (end_date is null or end_date > sysdate)
          and exists (select 1 from ticket_issues_i ti where ti.project_id = tp.project_id)
        order by UPPER(title_long) asc" project_id]"
        if {![empty_string_p $project_id]} { 
            ns_write "&nbsp; $project_title_long feature area:"
            set project_restrict_sql " and tp.project_id = $project_id"
        } else { 
            ns_write "&nbsp; feature area:"
            set project_restrict_sql {}
        }
        # HP wants multiselect yech.
        ns_write "[ad_db_select_widget -multiple 0 -size 1 -default $domain_id -option_list {{{all} {-- All Feature areas --}}} $db "select distinct td.title_long, td.domain_id 
        from ticket_domains td, ticket_domain_project_map tgm , ticket_projects tp 
        where td.domain_id = tgm.domain_id 
          and tgm.project_id = tp.project_id 
          and (tp.end_date is null or tp.end_date > sysdate) 
          and (td.end_date is null or tp.end_date > sysdate) $project_restrict_sql
          and exists (select 1 from ticket_issues_i ti where ti.domain_id = td.domain_id)
        order by UPPER(td.title_long) asc" domain_id]
     <input type=submit value=\"Go\">
     [export_ns_set_vars form [list domain_id project_id]]</form>"
    }

    # quick search
    #  we remove all restrictions and send back to index.tcl
    #  kludgey that we have to unrestrict slider variables 
    #  explicitly rather than have an ad_dimensional_unrestrict
    regsub "score\\*?," "$orderby," {} orderby_search
    ns_write "<form method=post action=\"index.tcl\">Quick search: <input type=text maxlength=100 name=query_string [export_form_value query_string]>
        [export_ns_set_vars form [list advs advs_results query_string domain_id submitby assign status created orderby]]
        <input type=hidden name=qs value=\"1\">
        <input type=hidden name=domain_id value=\"all\">
        <input type=hidden name=submitby value=\"any\">
        <input type=hidden name=assign value=\"any\">
        <input type=hidden name=status value=\"any\">
        <input type=hidden name=created value=\"any\">
        <input type=hidden name=orderby value=\"[philg_quote_double_quotes [ad_new_sort_by "score*" $orderby_search]]\">
        <input type=submit value=\"Go\"> &nbsp;&nbsp;&nbsp;&nbsp;<em>or</em> &nbsp; <a href=\"[ns_conn url]?advs_results=0&advs=1&[export_ns_set_vars url [list advs advs_results]]\">Advanced search</a> </form>"

    if {[lsearch $debug {query}] > -1} {
        ns_write "<pre>$query</pre>"
    }



    if { ! $advs || $advs_results } { 
        if { $expert } { 
            # now the table views
            set cust "[ns_conn url]?[export_ns_set_vars url [list customize ticket_table]]&customize=table&ticket_table="
            set use "[ns_conn url]?[export_ns_set_vars url ticket_table]&ticket_table="
            ns_write "Table Views: [ad_custom_list $db $user_id ticket_table $ticket_table table_view $use $cust]<br>"

            # now the sorts
            set cust "[ns_conn url]?[export_ns_set_vars url [list customize orderby ticket_sort]]&customize=sort&ticket_sort="
            set use "[ns_conn url]?[export_ns_set_vars url [list orderby ticket_sort]]&ticket_sort="
            ns_write "Sorts: [ad_custom_list $db $user_id ticket_sort $ticket_sort table_sort $use $cust "new sort"]<br>"
        }

        if { $advs } { 
            ns_write "<table border=0 cellspacing=0 cellpadding=3 width=100%>\n<tr>\n"
            ns_write "<th bgcolor=\"#ECECEC\">Advanced search </th></tr>\n"
        } else { 
            ns_write "[ad_dimensional $dimensional]<p>"
        }

        set selection [ns_db select $db $query] 
        ns_write "[ad_table -Taudit {msg_id} -Torderby $orderby -Tcolumns $col -Tpre_row_code $rowcode $db $selection $table_def]<p>"
    }

    if {$advs} { 
        set advs 1
        set advs_results 1 
        ns_write "<form>
 [ticket_advs_query_page_fragment $db]
 [export_ns_set_vars form [concat [ticket_exclude_regexp {^advs}] {qs}]]
 [export_form_vars advs advs_results]
 </form>"

    }
    
}

ns_write "[ad_footer]"
