ad_page_contract {
    Gives the site admin a comprehensive view of what's new at the site

    @author Philip Greenspun [philg@mit.edu]
    @creation-date July 4, 1999
    @cvs-id new-stuff.tcl,v 3.2.2.6 2000/09/22 01:34:16 kevin Exp
} {
    {only_from_new_users_p:notnull "f"}
    {n_days_ago:notnull,integer "7"}
}

if { $only_from_new_users_p == "t" } {
    set left_widget "from new users | <a href=\"new-stuff?[export_url_vars n_days_ago]&only_from_new_users_p=f\">expand to all users</a>"
    set user_class_description "new users"
} else {
    set left_widget "<a href=\"new-stuff?[export_url_vars n_days_ago]&only_from_new_users_p=t\">limit to new users</a> | from all users"
    set user_class_description "all users"
}

if { $n_days_ago == 1 } {
    set time_description "since yesterday morning"
} else {
    set time_description "in last $n_days_ago days"
}

set page_content ""

append page_content "[ad_admin_header "Stuff from $user_class_description $time_description"]

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
	lappend right_widget_items "<a href=\"new-stuff?[export_url_vars only_from_new_users_p]&n_days_ago=$n_days\">$n_days</a>"
    }
}

set right_widget [join $right_widget_items]

append page_content "<table width=100%><tr><td align=left>$left_widget<td align=right>$right_widget</a></table>\n"



set since_when [db_string date_n_days_ago {
    select sysdate - :n_days_ago from dual
}]

append page_content [ad_new_stuff $since_when $only_from_new_users_p "site_admin"]

append page_content "
[ad_admin_footer]
"

doc_return  200 text/html $page_content