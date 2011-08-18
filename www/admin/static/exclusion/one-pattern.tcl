# $Id: one-pattern.tcl,v 3.0 2000/02/06 03:30:46 ron Exp $
# 
# /admin/static/exclusion/one-pattern.tcl
#
# by jsc@arsdigita.com on November 6, 1999
#
# form to display all information about an exclusion pattern
# including facility to test run the pattern to see what matches
# and to delete it.


set_form_variables
# exclusion_pattern_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names, last_name, exc.*
from static_page_index_exclusion exc, users u
where u.user_id = exc.creation_user
and exc.exclusion_pattern_id = $exclusion_pattern_id"]

set_variables_after_query

ns_return 200 text/html "[ad_admin_header "One Exclusion Pattern"]

<h2>One Exclusion Pattern</h2>

[ad_admin_context_bar [list "../index.tcl" "Static Content"] "One Exclusion Pattern"]

<hr>

<blockquote>
<table border=0 width=60%>
<tr><th>Field</th><td>$match_field</td></tr>
<tr><th>Pattern Type</th><td>$like_or_regexp</td></tr>
<tr><th>Pattern</th><td>$pattern</td></tr>
<tr><th>Comment</th><td>$pattern_comment</td></tr>
<tr><th>Creation User</th><td>$first_names $last_name</td></tr>
<tr><th>Creation Date</th><td>$creation_date</td></tr>
</table>
</blockquote>

<ul>
<li><a href=\"test-pattern.tcl?[export_url_vars exclusion_pattern_id]\">test this pattern</a>
<p>
<li><a href=\"delete-one.tcl?[export_url_vars exclusion_pattern_id]\">delete this pattern</a>
</ul>

[ad_admin_footer]
"