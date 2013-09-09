# File:     /homepage/set-view.tcl

ad_page_contract {
    Sets a cookie to determine user's preferred view (in index view).

    @param view Which view to use in looking at homepage files (normal or tree)
    @param filesystem_node Used to determine a return location

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Sat Jan 22 23:03:44 EST 2000
    @cvs-id set-view.tcl,v 3.0.12.4 2000/07/21 04:00:46 ron Exp
} {
    view:notnull,trim
    filesystem_node:notnull,naturalnum
}

ad_set_cookie -replace t homepage_view $view
ad_returnredirect index?filesystem_node=$filesystem_node
