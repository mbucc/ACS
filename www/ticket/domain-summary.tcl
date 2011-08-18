# $Id: domain-summary.tcl,v 3.1.4.1 2000/04/27 18:54:09 carsten Exp $
# domain-summary.tcl
#
# hqm@arsdigita.com
#
# Summarize all domains
#

ad_page_variables {{orderby {title_long}} {return_url {/ticket/index.tcl?}} {project_id {}}}

set db [ns_db gethandle]

ReturnHeaders

set sql_restrict {}

if {![empty_string_p $project_id]} { 
    set project_title "- Project: [database_to_tcl_string $db "select title_long from ticket_projects where project_id = $project_id"]"
} else {
    set project_title {}
}

if {![empty_string_p $project_id]} {
    append sql_restrict " and tp.project_id = $project_id"
} 
ns_write "[ad_header "Feature Area Summaries"]
 <h3>Feature Area Summaries $project_title</h3>
 [ad_context_bar_ws_or_index [list $return_url "Ticket Tracker"]  "Feature Area Summaries"]
 <hr>"


set dimensional {
    {projectstate "Project State" open {
        {open "open" {where "(tp.end_date > sysdate or tp.end_date is null)"}}
        {closed "closed" {where "tp.end_date < sysdate"}}
        {all "all" {}}
    }}
    {public "Public" all {
        {yes "yes" {where "td.public_p = 't'"}}
        {no "no"  {where "td.public_p = 'f'"}}
        {all "all"  {}}
    }}
}

set table_def { 
    {title_long "Feature Area" {upper(td.title_long) $order} {<td><a href=\"[uplevel set return_url]&project_id=&domain_id=$domain_id\">$title_long</a></td>}}
    {total "Total" {total [ad_reverse $order]} bz}
    {open "Active" {open [ad_reverse $order]} bz}
    {closed "Closed" {closed [ad_reverse $order]} bz}
    {deferred "Deferred" {deferred [ad_reverse $order]} bz}
    {last_modified_pretty "Last Mod" {last_modified $order} bz}
    {oldest_pretty "Oldest" {oldest $order} bz}
}

set sql "select 
  td.domain_id, 
  td.title_long, 
  count(msg_id) as total,
  sum(decode(lower(status),'closed',1,0)) as closed,
  sum(decode(lower(status),'closed',0,'deferred',0,'defer',0,NULL,0,1)) as open,
  sum(decode(lower(status),'deferred',1,'defer',1,0)) as deferred,
  to_char(max(last_modified),'MM/DD/YY') as last_modified_pretty,
  to_char(min(posting_time),'MM/DD/YY') as oldest_pretty,
  max(last_modified) as last_modified,
  min(posting_time) as oldest
 from ticket_domains td, ticket_issues ti, ticket_projects tp
 where td.domain_id = ti.domain_id(+)
   and ti.project_id = tp.project_id $sql_restrict
   [ad_dimensional_sql $dimensional where]
 group by td.domain_id, td.title_long
 [ad_order_by_from_sort_spec $orderby $table_def]\n"




ns_write "[ad_dimensional $dimensional]<br> <blockquote>"
set selection [ns_db select $db $sql]
ns_write "[ad_table -Torderby $orderby $db $selection $table_def]
 </blockquote>
 [ad_footer]"
