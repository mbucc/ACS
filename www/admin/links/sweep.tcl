# $Id: sweep.tcl,v 3.0 2000/02/06 03:24:53 ron Exp $
# *** the "notify user who posted link" proc is totally broken
# -- philg 2/27/1999

# sweep out dead links from part or all of the links table

set_the_usual_form_variables

# page_id (could be "all"), verbose_p is optional

# want to turn this off when we haven't swept for a long time
set actually_send_email_p 0 

if { ![info exists verbose_p] } {
    set verbose_p 1
}

set db_conns [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_conns 0]
set db_sub [lindex $db_conns 1]

if { $page_id == "all" } {
    set page_id_clause ""
    set scope_description "all of the related links contributed to [ad_system_name]"
} else {
    # we're only sweeping links related to one page
    set page_id_clause "and links.page_id = $page_id"
    set url_stub [database_to_tcl_string $db "select url_stub from static_pages where page_id = $page_id"]
    set scope_description "related links contributed to <a href=\"/admin/static/page-summary.tcl?page_id=$page_id\">$url_stub</a>"
}

proc link_notify {db url new_status} {
    set selection [ns_db select $db "select l.page_id, url, link_title, email, pi.backlink, pi.backlink_title
from links l, page_ids pi
where url = '[DoubleApos $url]' 
and contact_p
and l.page_id = pi.page_id"]

    set body "The BooHoo automated link management system is unable to reach
$url

Its new status is [string toupper $new_status].  Links go from 'live' to 'coma' to
'dead' and then are removed.  Promotion in status occurs if the link
is unreachable one night.  A link that becomes reachable goes back to
live immediately.

Here are the pages that will no longer have $url 
as a related link:

"

    while {[ns_db getrow $db $selection]} {

	set_variables_after_query

	append body "   $backlink ($backlink_title)\n"

    }

    append body "

If you have moved servers or something and the URL is no longer valid,
then just come back to the pages above and add the new URL.  The old
dead one will get weeded out within a day or two.

"

    # we don't want errors killing us
    
    catch { ns_sendmail $email "philg@mit.edu" "$url is unreachable" $body }

    
}

ReturnHeaders

ns_write "[ad_admin_header "Sweeping"]

<h2>Sweeping</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "Sweeping"]

<hr>

Scope:  $scope_description

<p>

This program cycles through links that 

<ol>
<li>haven't been checked in the last 24 hours
<li>aren't in the \"removed\" status
</ol>

Any link that is reachable is promoted to \"live\" status if it wasn't
already there.  Links that aren't reachable go through a life cycle of
live, coma, dead, and removed.  We test the coma and dead links first.

<ul>

"

set selection [ns_db select $db "select links.page_id, url, link_title, status, contact_p, sp.url_stub
from links, static_pages sp 
where links.page_id = sp.page_id
and links.status <> 'removed'
and (checked_date is null or checked_date + 1 < sysdate) $page_id_clause
order by links.status, links.url"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_log Notice "attempting to reach $url, whose current status is $status"
    if ![util_link_responding_p $url] {
	# couldn't get the URL
	if { $status == "live" } {
	    set new_status "coma"
	    ns_db dml $db_sub "update links set status='coma' where page_id = $page_id and url='[DoubleApos $url]'"
	} elseif { $status == "coma" } {
	    set new_status "dead"
	    ns_db dml $db_sub "update links set status='dead' where page_id = $page_id and url='[DoubleApos $url]'"
	    if { $contact_p == "t" && $actually_send_email_p } {
		link_notify $db_sub $url dead
	    }
	} elseif { $status == "dead" } {
	    set new_status "removed"
	    if { $contact_p == "t" && $actually_send_email_p } {
		link_notify $db_sub $url removed
	    }
	    ns_db dml $db_sub "update links set status='removed' where page_id = $page_id and url='[DoubleApos $url]'"
	}

	ns_write "<li>Could not reach <a href=\"$url\">$link_title</a>.  Status has gone from $status to $new_status.\n"

    } else {
	# we made it
	if { $verbose_p == 1 } {
	    ns_write "<li>Successfully reached <a href=\"$url\">$link_title</a>.\n"
	}
	if { $status != "live" } {
	    # was marked coma or dead, but now it is back
	    ns_db dml $db_sub "update links set status='live' where page_id = $page_id and url='[DoubleApos $url]'"
	    ns_write "  Updated status to \"live\" (from \"$status\")."
	}
    }
    # either way, let's mark this URL as having been checked
    ns_db dml $db_sub "update links set checked_date = sysdate where page_id = $page_id and url='[DoubleApos $url]'"
}

ns_write "
</ul>
[ad_admin_footer]
"
