# new-stuff.tcl

ad_page_contract {
    gives the random user a comprehensive view of what's 
    new at the site

    @author philg@mit.edu
    @creation-date July 4, 1999
    @cvs-id new-stuff.tcl,v 3.5.2.4 2000/09/22 01:39:18 kevin Exp
} {
    {n_days_ago 7}
}

if { [im_enabled_p] && [ad_parameter KeepSharedInfoPrivate intranet 0] } {
    if { ![im_user_is_authorized_p [ad_get_user_id]] } {
	im_restricted_access
    }
}

if { $n_days_ago == 1 } {
    set time_description "since yesterday morning"
} else {
    set time_description "in last $n_days_ago days"
}


append doc_body "[ad_header "New Stuff $time_description"]

<h2>New Stuff $time_description</h2>

[ad_context_bar_ws_or_index "New Stuff"]

<hr>

"

set n_days_possible [list 1 2 3 4 5 6 7 14 30]

foreach n_days $n_days_possible {
    if { $n_days == $n_days_ago } {
	# current choice, just the item
	lappend right_widget_items $n_days
    } else {
	lappend right_widget_items "<a href=\"new-stuff?n_days_ago=$n_days\">$n_days</a>"
    }
}

set right_widget [join $right_widget_items]

append doc_body "<table width=100%><tr><td align=left>&nbsp;<td align=right>N days: $right_widget</a></tr></table>

<p>

<blockquote>
<font size=-2 face=\"verdana, arial, helvetica\">

Please wait while this program sweeps dozens of database tables
looking for new content...

</font>
</blockquote>
<p>
"

set since_when [db_string since_when "select sysdate - :n_days_ago from dual"]

append doc_body "[ad_new_stuff $since_when "f" "web_display"]

[ad_footer]
"

db_release_unused_handles
doc_return 200 text/html $doc_body
