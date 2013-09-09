# www/portals/index.tcl

ad_page_contract {
    calendar for sloan portal

    @author aileen@mit.edu
    @author randyg@arsdigita.com
    @param date
    @creation-date Feb 2000
    @cvs-id calendar.tcl,v 3.2.2.7 2000/09/22 01:39:00 kevin Exp
} {
    {date:notnull}
}

set user_id [ad_verify_and_get_user_id]

doc_return  200 text/html "
[ad_header "Calendars @ [ad_system_name]"]
<h2>Calendar</h2>

[ad_context_bar_ws_or_index [list /portals/user$user_id-1.ptl "Portal"] "Calendar"]

<hr>
[edu_calendar_for_portal $date]
[ad_footer]
"





