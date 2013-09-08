# www/calendar/index.tcl  
ad_page_contract {
    This is the user index page for the calendar module
    It displays a list of upcoming events, lists additional categories, 
    and presents links to add items and view info on expired events.
    The page is sensitive to system parameters SystemName, and calendar
    parameters ApprovalPolicy, MaxEventsOnIndexPage, MinNumberForTopLink.

    Number of queries: 3

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1998-11-18
    @cvs-id index.tcl,v 3.4.2.7 2000/09/22 01:37:05 kevin Exp
    
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



ad_scope_error_check

set user_id [ad_scope_authorize $scope all group_member registered]

set page_title [ad_parameter SystemName calendar "Calendar Index"]




##### PAGE TOP

set page_content "

[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws_or_index [ad_parameter SystemName calendar "Calendar"]]

<hr>
[ad_scope_navbar]
"





##### TABLE 1 - Upcoming Events + Post New link

append page_content "<H4>Upcoming Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"


set event_counter 0


## Can this break? Can it be set negative, or to zero? What if it is unset? -MJS 7/14
set param_MaxEventsOnIndexPage [ad_parameter MaxEventsOnIndexPage calendar 20]


## We have to wrap this in an extra select, otherwise rownum doesn't sort.
## The other way to do it would be to select all the rows, 
## and only display up to MaxEvents. -MJS

db_foreach relevant_events "
select * from (select start_date, 
end_date,
calendar_id,
title
from calendar c, calendar_categories cc
where sysdate < c.expiration_date
and c.approved_p = 't'
and c.category_id=cc.category_id
and [ad_scope_sql cc]
order by start_date)
where rownum <= :param_MaxEventsOnIndexPage + 1

" {
    ## We could select 'to_char MONTH DD YYYY', 
    ## however util_AnsiDatetoPrettyDate is a little smarter than Oracle.  
    ## Oracle returns the month in all capital
    ## letters and doesn't trim leading zeroes. -MJS 7/14
    
    set pretty_start_date [util_AnsiDatetoPrettyDate $start_date]
    set pretty_end_date [util_AnsiDatetoPrettyDate $end_date]
    
    incr event_counter
    
    if { $event_counter <= $param_MaxEventsOnIndexPage } {
	
	append page_content "
	<TR><TD>$pretty_start_date</TD> <TD>-</TD> <TD ALIGN=RIGHT>$pretty_end_date</TD>
	<TD><a href=\"item?[export_url_scope_vars calendar_id]\">
	$title</a></TD></TR>\n"
	
    }
    
} if_no_rows {
    
    append page_content "<TR><TD>There are no upcoming events</TD></TR>"
}


## set param_MinNumberForTopLink [ad_parameter MinNumberForTopLink calendar]

## Display a link to add an item, but only if there are a minimum number of
## items already displayed. 

## I killed this.  It made no sense to me. -MJS 7/19


switch [ad_parameter ApprovalPolicy calendar] {
    
    open {
	append page_content "
	<TR><TD><!--vertical gap--></TD></TR>
	<TR><TD><a href=\"post-new?[export_url_scope_vars]\">Post an event</a></TD></TR>"
    }
    
    wait {
	append page_content "
	<TR><TD><!--vertical gap--></TD></TR>
	<TR><TD><a href=\"post-new?[export_url_scope_vars]\">Suggest an event</a></TD></TR>"
    }
    
    closed {}
    
    default {}
    
}


append page_content "</TABLE></BLOCKQUOTE>\n\n"





##### TABLE 2 - Browse by Category

## If there are more events than we are allowed to display, 
## then offer the option to browse by category



if { $event_counter > $param_MaxEventsOnIndexPage } {

    append page_content "
    <H4>More Upcoming Events</H4>
    For events further in the future, please browse by category:
    
    <BLOCKQUOTE><TABLE>"
    

    db_foreach categories "
    select c.category_id, cc.category, count(*) as n_events
    from calendar c, calendar_categories cc
    where sysdate < c.expiration_date
    and c.approved_p = 't'
    and c.category_id=cc.category_id
    and [ad_scope_sql cc]
    group by c.category_id, cc.category
    order by n_events desc
    " {

	append page_content "
	<TR><TD><a href=category-one?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]>$category</a></TD>
	<TD ALIGN=RIGHT>$n_events</TD></TR>"
	
    } if_no_rows {
	## Shouldn't happen
	append page_content "
	<TR><TD></TD> <TD>There are no categories to browse</TD></TR>"
    }
    
    append page_content "</TABLE></BLOCKQUOTE>\n"

}


##### Check The Archives for past events

db_1row num_expired_events "
select count(*) as num_expired_events
from calendar c, calendar_categories cc 
where sysdate > c.expiration_date
and c.category_id=cc.category_id
and [ad_scope_sql cc]
"

db_release_unused_handles

if { $num_expired_events > 0 } {
    
    append page_content "
    <H4>Past Events</H4>
    To dig up information on an event that you missed, check 
    <a href=\"archives\">the archives</a>.\n\n"

}

append page_content "<p></p>[ad_scope_footer]"

doc_return  200 text/html $page_content

## END FILE index.tcl







