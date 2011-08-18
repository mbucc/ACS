# $Id: project-summary.tcl,v 3.1 2000/02/20 21:21:56 davis Exp $
# project-summary.tcl
#
# hqm@arsdigita.com
#
# Summarize all projects
#

ad_page_variables {{orderby {title}} {return_url {/ticket/index.tcl?}}}

set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_header "Project Summaries"]
 <h2>Project Summaries</h2>
 [ad_context_bar_ws_or_index [list $return_url "Ticket Tracker"]  "Project Summaries"]
 <hr>"

set dimensional {
    {projectstate "Project State" open {
        {open "open" {where "(tp.end_date > sysdate or tp.end_date is null)"}}
        {closed "closed" {where "tp.end_date < sysdate"}}
        {all "all" {}}
    }}
    {public "Public" all {
        {yes "yes" {where "tp.public_p = 't'"}}
        {no "no"  {where "tp.public_p = 'f'"}}
        {all "all"  {}}
    }}
    {public "In the last" all {
        {year "year" {where "ti.posting_time + 365 > sysdate"}}
        {3month "3 months"  {where "ti.posting_time + 90 > sysdate"}}
        {month "month"  {where "ti.posting_time + 30 > sysdate"}}
        {all "all" {}}
    }}
}

set table_def { 
    {title "Project" {upper(title) $order} {}}
    {total "Total" {total [ad_reverse $order]} bz}
    {open "Active" {open [ad_reverse $order]} bz}
    {closed "Closed" {closed [ad_reverse $order]} bz}
    {deferred "Deferred" {deferred [ad_reverse $order]} bz}
    {lastmod "Last Mod" {} bz}
    {oldest "Oldest" {} bz}
    {viewby "View" no_sort {<td>
        <a href="domain-summary.tcl?[uplevel export_url_vars return_url]&project_id=$project_id">by feature area</a>
        | <a href=\"[uplevel set return_url]&project_id=$project_id\">project tickets</a></td>}

    }
}

set sql "select 
  tp.project_id, 
  tp.title, 
  tp.version,
  count(msg_id) as total,
  sum(decode(lower(status),'closed',1,0)) as closed,
  sum(decode(lower(status),'closed',0,'deferred',0,'defer',0,NULL,0,1)) as open,
  sum(decode(lower(status),'deferred',1,'defer',1,0)) as deferred,
  max(last_modified) as lastmod,
  min(posting_time) as oldest
 from ticket_projects tp, ticket_issues ti
 where tp.project_id = ti.project_id(+)
   [ad_dimensional_sql $dimensional where]
 group by tp.project_id, tp.title, tp.version
 [ad_order_by_from_sort_spec $orderby $table_def]\n"




ns_write "[ad_dimensional $dimensional]<br> <blockquote>"
set selection [ns_db select $db $sql]
ns_write "[ad_table -Torderby $orderby $db $selection $table_def]
 </blockquote>
 [ad_footer]"
