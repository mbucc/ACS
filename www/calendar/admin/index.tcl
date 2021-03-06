# www/calendar/admin/index.tcl
ad_page_contract {
    This is the user-admin index page for the calendar module
    It displays a list of all events, both upcoming and expired. 
    It highlights red the events that are unapproved, and presents
    links to admin/item.tcl where approval can be granted.

    Number of queries: 1

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1998-11-18
    @cvs-id index.tcl,v 3.2.2.6 2000/09/22 01:37:06 kevin Exp
    
} {
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}

}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set page_content "
[ad_scope_admin_header "Calendar Administration"]
[ad_scope_admin_page_title "Calendar Administration"]
[ad_scope_admin_context_bar "Calendar"]

<hr>

"


set counter_upcoming 0 
set counter_expired 0

set table_html_upcoming "<H4>Upcoming Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

set table_html_expired "<H4>Expired Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

db_foreach items "
select
start_date,
end_date,
title, approved_p, calendar_id,
expired_p(c.expiration_date) as expired_p
from calendar c , calendar_categories cc
where c.category_id=cc.category_id
and [ad_scope_sql cc]
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
    <TD><a href=\"item?[export_url_scope_vars calendar_id]\">$title</a>"
    
    
    if { $approved_p == "f" } {
	append [set meta_table] "<TD><font color=red>not approved</font></TD>"
    }
    
    append [set meta_table] "</TR>\n"
    
}


if {$counter_upcoming > 0} {
    append page_content $table_html_upcoming "</TABLE></BLOCKQUOTE>\n\n"
}

if {$counter_expired > 0} {
    append page_content $table_html_expired "</TABLE></BLOCKQUOTE>\n\n"
}



append page_content "

<UL>

<li><a href=\"post-new?[export_url_scope_vars]\">Add an event</a>

<li><a href=\"categories?[export_url_scope_vars]\">Browse Categories</a>

</ul>

[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE index.tcl


