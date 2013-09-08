# File:     /homepage/set-view-nh.tcl
ad_page_contract {
    Sets a cookie to determine user's preferred view (in neighborhood view).

    @param view Which view to use in looking at homepage files (normal or tree)
    @param neighborhood_node Used to determine a return location

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Sat Jan 22 23:03:44 EST 2000
    @cvs-id set-view-nh.tcl,v 3.0.12.4 2000/07/21 04:00:46 ron Exp
} {
    view:notnull,trim
    neighborhood_node:notnull,naturalnum
}

ad_set_cookie -replace t neighborhood_view $view
ad_returnredirect neighborhoods?neighborhood_node=$neighborhood_node
