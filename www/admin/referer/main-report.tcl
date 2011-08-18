# $Id: main-report.tcl,v 3.0 2000/02/06 03:27:40 ron Exp $
# we assume that a publisher is here because he or she wants to see
# what are the most important foreign URLs generating referrals to 
# this site.  So the default is to order results by n_clicks desc

set_the_usual_form_variables 0

# n_days (default is "all" if not specified)
# optional minimum 
# optional order_by

if { ![info exists order_by] || $order_by == "n_clicks" } {
    set order_by_columns "n_clicks desc, foreign_url, local_url"
} else {
    set order_by_columns "foreign_url, local_url"
}

# let's try to set up some reasonable minimums

if { ![info exists minimum] } {
    # no minimum specified
    if { ([info exists n_days] && $n_days == 1) && ([ad_parameter TrafficVolume] == "small")} {
	# no minimum
	set minimum 1
    } else {
	if { [ad_parameter TrafficVolume] == "small" } {
	    set minimum 2
	} else {
	    # not a small site 
	    if { ([info exists n_days] && $n_days < 7) } {
		set minimum 3
	    } else {
		# more than 7 days on a non-small site
		set minimum 10
	    }
	}
    }
}

if { [info exists minimum] } {
    set having_clause "\nhaving sum(click_count) >= $minimum"
} else {
    set having_clause ""
}

if { ![info exists n_days] || $n_days == "all" } {
    set query "select local_url, foreign_url, sum(click_count) as n_clicks
from referer_log
group by local_url, foreign_url $having_clause
order by $order_by_columns"
} elseif { $n_days > 1 } {
    set query "select local_url, foreign_url, sum(click_count) as n_clicks
from referer_log
where entry_date > sysdate - $n_days
group by local_url, foreign_url $having_clause
order by $order_by_columns"
} else  {
    # just one day, so we don't have to group by 
    if { [info exists minimum] } {
	set and_clause "\nand click_count >= $minimum"
    } else {
	set and_clause ""
    }
    set query "select local_url, foreign_url, click_count as n_clicks
from referer_log
where entry_date > sysdate - 1 $and_clause
order by $order_by_columns"
}

ReturnHeaders

ns_write "[ad_admin_header "Referrals from foreign URLs to [ad_system_name]"]

<h2>Referrals from foreign URLs</h2>

[ad_admin_context_bar [list "index.tcl" "Referrals"] "Main Report"]


<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db $query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"one-url-pair.tcl?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">[ns_quotehtml $foreign_url]
-&gt; [ns_quotehtml $local_url]</a>: $n_clicks</a>
"
}

ns_write "
</ul>

[ad_admin_footer]
"
