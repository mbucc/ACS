# /www/admin/bboard/index.tcl
ad_page_contract {
    Front page for bboard hyper-administration

    @cvs-id index.tcl,v 3.2.2.4 2000/09/22 01:34:22 kevin Exp
} {
}

# -----------------------------------------------------------------------------

append page_content "
[ad_admin_header "[bboard_system_name] Hyper-Administration"]

<h2>Hyper-Administration</h2>

[ad_admin_context_bar "BBoard Hyper-Administration"]

<hr>

<ul>

<h4>Active topics</h4>
"

set count 0
set inactive_title_shown_p 0

db_foreach bboard_topics "
select active_p,
       topic,
       topic_id
from   bboard_topics 
order by active_p desc, upper(topic)" {

    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		append page_content "<li>No active topics"
	    }
	    set inactive_title_shown_p 1
	    append page_content "<h4>Inactive topics</h4>"
	}
	set anchor "activate"
    } else {
	set anchor "deactivate"
    }

    append page_content "<li><a href=\"administer?[export_url_vars topic topic_id]\">$topic</a> (<a href=\"toggle-active-p?[export_url_vars topic]\">$anchor</a>)\n"

    incr count
}

append page_content "

<p>

<li><a href=\"add-new-topic\">Add New Topic</a> (i.e., add a new discussion board)

</ul>

Documentation for this subsystem is available at 
<a href=\"/doc/bboard\">/doc/bboard.html</a>.

[ad_admin_footer]"


doc_return  200 text/html $page_content
