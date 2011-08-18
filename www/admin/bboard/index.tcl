# $Id: index.tcl,v 3.0 2000/02/06 02:49:18 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "[bboard_system_name] Hyper-Administration"]

<h2>Hyper-Administration</h2>

[ad_admin_context_bar "BBoard Hyper-Administration"]

<hr>

<ul>

<h4>Active topics</h4>
"

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

# we successfully opened the database

set selection [ns_db select $db "select * from bboard_topics order by active_p desc, upper(topic)"]

set count 0
set inactive_title_shown_p 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		ns_write "<li>No active topics"
	    }
	    set inactive_title_shown_p 1
	    ns_write "<h4>Inactive topics</h4>"
	}
	set anchor "activate"
    } else {
	set anchor "deactivate"
    }

    set_variables_after_query
    ns_write "<li><a href=\"administer.tcl?[export_url_vars topic topic_id]\">$topic</a> (<a href=\"toggle-active-p.tcl?[export_url_vars topic]\">$anchor</a>)\n"

    incr count
}


ns_write "

<p>

<li><a href=\"add-new-topic.tcl\">Add New Topic</a> (i.e., add a new discussion board)

</ul>

Documentation for this subsystem is available at 
<a href=\"/doc/bboard.html\">/doc/bboard.html</a>.

[ad_admin_footer]"
