# new-stuff.tcl
# by philg@mit.edu on July 4, 1999
#
# $Id: new-stuff.tcl,v 3.1.4.1 2000/03/15 18:36:23 curtisg Exp $

# gives the random user a comprehensive view of what's 
# new at the site

set_the_usual_form_variables 0

# n_days_ago 

set db [ns_db gethandle]

if { [im_enabled_p] && [ad_parameter KeepSharedInfoPrivate intranet 0] } {
    if { ![im_user_is_authorized_p $db [ad_get_user_id]] } {
	im_restricted_access
    }
}

if ![info exists n_days_ago] {
    set n_days_ago 7
}

if { $n_days_ago == 1 } {
    set time_description "since yesterday morning"
} else {
    set time_description "in last $n_days_ago days"
}

ReturnHeaders

ns_write "[ad_admin_header "New Stuff $time_description"]

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
	lappend right_widget_items "<a href=\"new-stuff.tcl?n_days_ago=$n_days\">$n_days</a>"
    }
}

set right_widget [join $right_widget_items]

ns_write "<table width=100%><tr><td align=left>&nbsp;<td align=right>N days: $right_widget</a></tr></table>

<p>

<blockquote>
<font size=-2 face=\"verdana, arial, helvetica\">

Please wait while this program sweeps dozens of database tables
looking for new content...

</font>
</blockquote>

<p>

"

set since_when [database_to_tcl_string $db "select sysdate - $n_days_ago from dual"]

ns_write "[ad_new_stuff $db $since_when "f" "web_display"]

[ad_admin_footer]
"

