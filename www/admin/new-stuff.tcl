# /admin/new-stuff.tcl
#
# by philg@mit.edu on July 4, 1999
#
# $Id: new-stuff.tcl,v 3.0 2000/02/06 02:44:49 ron Exp $

# gives the site admin a comprehensive view of what's 
# new at the site

set_the_usual_form_variables 0

# only_from_new_users_p, n_days_ago 

if ![info exists only_from_new_users_p] {
    set only_from_new_users_p "f"
}

if ![info exists n_days_ago] {
    set n_days_ago 7
}

if { $only_from_new_users_p == "t" } {
    set left_widget "from new users | <a href=\"new-stuff.tcl?[export_url_vars n_days_ago]&only_from_new_users_p=f\">expand to all users</a>"
    set user_class_description "new users"
} else {
    set left_widget "<a href=\"new-stuff.tcl?[export_url_vars n_days_ago]&only_from_new_users_p=t\">limit to new users</a> | from all users"
    set user_class_description "all users"
}

if { $n_days_ago == 1 } {
    set time_description "since yesterday morning"
} else {
    set time_description "in last $n_days_ago days"
}

ReturnHeaders

ns_write "[ad_admin_header "Stuff from $user_class_description $time_description"]

<h2>Stuff from $user_class_description $time_description</h2>

[ad_admin_context_bar "New Stuff"]

<hr>

"


set n_days_possible [list 1 2 3 4 5 6 7 14 30]

foreach n_days $n_days_possible {
    if { $n_days == $n_days_ago } {
	# current choice, just the item
	lappend right_widget_items $n_days
    } else {
	lappend right_widget_items "<a href=\"new-stuff.tcl?[export_url_vars only_from_new_users_p]&n_days_ago=$n_days\">$n_days</a>"
    }
}

set right_widget [join $right_widget_items]

ns_write "<table width=100%><tr><td align=left>$left_widget<td align=right>$right_widget</a></table>\n"

set db [ns_db gethandle]

set since_when [database_to_tcl_string $db "select sysdate - $n_days_ago from dual"]

ns_write [ad_new_stuff $db $since_when $only_from_new_users_p "site_admin"]

ns_write "

[ad_admin_footer]

"

