# /www/ticket/user-summary.tcl
ad_page_contract {
    Summarize by submitting user tickets in state blah

    @param orderby the sort order for the display
    @param return_url where to go when we are done
    @param project_id a project to restrict to
    @param domain_id a domain to restrict to

    @author hqm@arsdigita.com
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id user-summary.tcl,v 3.4.2.5 2000/09/22 01:39:24 kevin Exp
} {
    {orderby "user"}
    {return_url "/ticket/index.tcl?"} 
    {project_id:integer ""} 
    {domain_id:integer ""}
}

# -----------------------------------------------------------------------------

set sql_restrict {}

if {![empty_string_p $project_id]} {
    append sql_restrict " and ti.project_id = :project_id"
} 
if {![empty_string_p $project_id]} {
    append sql_restrict " and ti.domain_id = :domain_id"
} 

append page_content "
[ad_header "User Submission Summaries"]

<h2>User Ticket Submission Summaries</h2>

[ad_context_bar_ws_or_index [list $return_url "Ticket Tracker"]  "User Summaries"]

<hr>
"

set dimensional {
    {projectstate "Project State" open {
        {open "open" {where "(tp.end_date > sysdate or tp.end_date is null)"}}
        {closed "closed" {where "tp.end_date < sysdate"}}
        {all "all" {}}
    }}
    {public "In the last" all {
        {year "year" {where "ti.posting_time + 365 > sysdate"}}
        {3month "3 months"  {where "ti.posting_time + 90 > sysdate"}}
        {month "month"  {where "ti.posting_time + 30 > sysdate"}}
        {all "all" {}}
    }}
}

set table_def { 
    {user "User" {upper(last_name) $order, upper(first_names) $order} {<td>[ticket_user_display $user_name $email $user_id]</td>}}
    {total "Total" {total [ad_reverse $order]} bz}
    {open "Active" {open [ad_reverse $order]} bz}
    {closed "Closed" {closed [ad_reverse $order]} bz}
    {deferred "Deferred" {deferred [ad_reverse $order]} bz}
    {lastmod "Lastest" {} bz}
    {oldest "Oldest" {} bz}
}

set sql "select 
  u.email, u.user_id, 
  u.last_name || ', ' ||  u.first_names  as user_name,
  count(msg_id) as total,
  sum(decode(lower(status_class),'closed',1,0)) as closed,
  sum(decode(lower(status_class),'closed',0,'deferred',0,'defer',0,NULL,0,1)) as open,
  sum(decode(lower(status_class),'deferred',1,'defer',1,0)) as deferred,
  max(last_modified) as lastmod,
  min(posting_time) as oldest
 from ticket_domains td, ticket_issues ti, ticket_projects tp, users u
 where ti.user_id = u.user_id 
   and td.domain_id = ti.domain_id(+)
   and ti.project_id = tp.project_id $sql_restrict
   [ad_dimensional_sql $dimensional where]
 group by u.email, u.first_names, u.last_name, u.user_id
 [ad_order_by_from_sort_spec $orderby $table_def]\n"

set bind_vars [ad_tcl_vars_to_ns_set project_id domain_id]

append page_content "
[ad_dimensional $dimensional]<br> <blockquote>

[ad_table -Torderby $orderby -bind $bind_vars \
	ticket_info_for_one_user $sql $table_def]
 </blockquote>
 [ad_footer]"

doc_return  200 text/html $page_content