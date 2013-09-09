# index.tcl

ad_page_contract {
    Top-level admin page for polls.

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id index.tcl,v 3.3.2.4 2000/09/22 01:35:46 kevin Exp
} {
}

# make sure user is registered

ad_maybe_redirect_for_registration

# return the page

set page_html "
[ad_admin_header "Polls Admin"]
<h2>Polls Admin</h2>
[ad_admin_context_bar Polls]
<hr>

Documentation:  <a href=\"/doc/poll\">/doc/poll</a>

<h3>Polls</h3>

<ul>
"
set count 0
set written_inactive_header_p 0


db_foreach get_polls  "
select poll_id, name, start_date, end_date, require_registration_p,
       poll_is_active_p(start_date, end_date) as active_p
  from polls
 order by active_p desc, name
" {

    if { $active_p == "f" && !$written_inactive_header_p } {
	set written_inactive_header_p 1
	append page_html "<h4>Inactive</h4>\n"
    }

    if { $require_registration_p == "t" } {
	set require_registration "<font size=-1>(requires registration)</font>"
    } else {
	set require_registration ""
    }

    append page_html "<li> <a href=\"one-poll?[export_url_vars poll_id]\">$name</a> from $start_date to $end_date $require_registration\n"

    incr count
} if_no_rows {
    append page_html "<li> No polls found"
}

db_release_unused_handles

append page_html "

<p>

<li><a href=\"poll-new\">create a new poll</a>

</ul>

<p>

[ad_admin_footer]
"

doc_return  200 text/html $page_html

