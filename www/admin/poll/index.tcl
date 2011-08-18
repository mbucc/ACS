# $Id: index.tcl,v 3.0 2000/02/06 03:26:57 ron Exp $
# index.tcl - top-level admin page for polls

# make sure user is registered

ad_maybe_redirect_for_registration

# return the page

ReturnHeaders

ns_write "
[ad_admin_header "Polls Admin"]
<h2>Polls Admin</h2>
[ad_admin_context_bar Polls]
<hr>

Documentation:  <a href=\"/doc/poll.html\">/doc/poll.html</a>

<h3>Polls</h3>

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "
select poll_id, name, start_date, end_date, require_registration_p,
       poll_is_active_p(start_date, end_date) as active_p
  from polls
 order by active_p desc, name
"]

set count 0
set written_inactive_header_p 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $active_p == "f" && !$written_inactive_header_p } {
	set written_inactive_header_p 1
	ns_write "<h4>Inactive</h4>\n"
    }

    if { $require_registration_p == "t" } {
	set require_registration "<font size=-1>(requires registration)</font>"
    } else {
	set require_registration ""
    }

    ns_write "<li> <a href=\"one-poll.tcl?[export_url_vars poll_id]\">$name</a> from $start_date to $end_date $require_registration\n"

    incr count
}

if { $count == 0 } {
    ns_write "<li> No polls found"
}

ns_write "

<p>

<li><a href=\"poll-new.tcl\">create a new poll</a>

</ul>

<p>

[ad_admin_footer]
"



