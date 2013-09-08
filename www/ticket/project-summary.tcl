# /www/ticket/project-summary.tcl
ad_page_contract {
    Summarize all projects

    @param orderby heading to sort on
    @param return_url where to send them back to

    @author hqm@arsdigita.com
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id project-summary.tcl,v 3.3.2.5 2000/09/22 01:39:24 kevin Exp
} {
    {orderby "title"} 
    {return_url "/ticket/index.tcl?"}
}

# -----------------------------------------------------------------------------

set page_content "
[ad_header "Project Summaries"]

<h2>Project Summaries</h2>

[ad_context_bar_ws_or_index [list $return_url "Ticket Tracker"]  "Project Summaries"]
 
<hr>
"


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
    {posted "In the last" all {
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
        <a href="domain-summary?[uplevel export_url_vars return_url]&project_id=$project_id">by feature area</a>
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

append page_content "
[ad_dimensional $dimensional]<br> 
<blockquote>

[ad_table -Torderby $orderby project_summary_table $sql $table_def]
 </blockquote>

 [ad_footer]
"

doc_return  200 text/html $page_content