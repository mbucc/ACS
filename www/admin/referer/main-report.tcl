# /www/admin/referer/main-report.tcl
#

ad_page_contract {
    Shows a report of the foreign URLs that are referring people to the site.

    @param n_days the number of days before today to show referrals from.
    @param minimum minimum number of referrals from a site for it to show up on the report.
    @param order_by specifies whether the report is ordered by number of referrals or by URL

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 4 July 1998
    @cvs-id main-report.tcl,v 3.3.2.6 2000/09/22 01:35:59 kevin Exp

    we assume that a publisher is here because he or she wants to see
    what are the most important foreign URLs generating referrals to 
    this site.  So the default is to order results by n_clicks desc

} {
    n_days:optional,sql_identifier
    minimum:optional,integer
    order_by:optional
}


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
    set having_clause "\nhaving sum(click_count) >= :minimum"
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
where entry_date > sysdate - :n_days
group by local_url, foreign_url $having_clause
order by $order_by_columns"
} else  {
    # just one day, so we don't have to group by 
    if { [info exists minimum] } {
	set and_clause "\nand click_count >= :minimum"
    } else {
	set and_clause ""
    }
    set query "select local_url, foreign_url, click_count as n_clicks
from referer_log
where entry_date > sysdate - 1 $and_clause
order by $order_by_columns"
}


set page_content "[ad_admin_header "Referrals from foreign URLs to [ad_system_name]"]

<h2>Referrals from foreign URLs</h2>

[ad_admin_context_bar [list "" "Referrals"] "Main Report"]

<hr>

<ul>

"



db_foreach referer_summary $query {
    append page_content "<li><a href=\"one-url-pair?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">[ns_quotehtml $foreign_url]
-&gt; [ns_quotehtml $local_url]</a>: $n_clicks</a>
"
}

append page_content "
</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content

