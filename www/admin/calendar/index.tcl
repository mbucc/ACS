# www/admin/calendar/index.tcl
ad_page_contract {
    This is the Site Wide Administrator Page for the calendar module.
    It displays a list of upcoming events, expired events and a link 
    to categories
    
    Number of queries: 1
    
    @author unknown
    @creation-date 1998-??-??
    @cvs-id index.tcl,v 3.2.2.5 2000/09/22 01:34:26 kevin Exp
    
} {}


set page_content "

[ad_admin_header "Calendar Administration"]
<h2>Calendar Administration</h2>
[ad_admin_context_bar "Calendar"]

<hr>

<ul>
"


set query_calendar_all "
   select title, approved_p, start_date, end_date, calendar_id,
          expired_p(expiration_date) as expired_p
     from calendar
    order by expired_p, creation_date desc"

set table_html_upcoming "<H4>Upcoming Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

set table_html_expired "<H4>Expired Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

set counter_upcoming 0 
set counter_expired 0

db_foreach all_events  "
select
start_date,
end_date,
title, approved_p, calendar_id,
expired_p(c.expiration_date) as expired_p
from calendar c
order by start_date asc
" {
    
    set pretty_start_date [util_AnsiDatetoPrettyDate $start_date]
    set pretty_end_date [util_AnsiDatetoPrettyDate $end_date]

    ## We use meta_table to store the name of the tcl variable
    ## so we can switch back and forth writing between two html tables
    
    if { $expired_p == "f" } {
	set meta_table "table_html_upcoming"
	incr counter_upcoming

    } else {
	set meta_table "table_html_expired"
	incr counter_expired
    }


    append [set meta_table] "
    <TR><TD>$pretty_start_date <TD>- <TD ALIGN=RIGHT>$pretty_end_date 
    <TD><a href=\"item?[export_url_vars calendar_id]\">$title</a>"
    
    
    if { $approved_p == "f" } {
	append [set meta_table] "<TD><font color=red>not approved</font></TD>"
    }
    
    append [set meta_table] "</TR>\n"
    
}

db_release_unused_handles

if {$counter_upcoming > 0} {
    append page_content $table_html_upcoming "</TABLE></BLOCKQUOTE>\n\n"
}

if {$counter_expired > 0} {
    append page_content $table_html_expired "</TABLE></BLOCKQUOTE>\n\n"
}





append page_content "
<P>
<li><a href=\"categories\">categories</a>
</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE index.tcl

