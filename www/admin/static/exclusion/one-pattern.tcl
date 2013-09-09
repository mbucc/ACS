ad_page_contract {
    one-pattern.tcl,v 3.2.2.4 2000/09/22 01:36:10 kevin Exp
    
    /admin/static/exclusion/one-pattern.tcl

    by jsc@arsdigita.com on November 6, 1999
     form to display all information about an exclusion pattern
    including facility to test run the pattern to see what matches
    and to delete it.
} {
    exclusion_pattern_id:integer
}

db_1row static_exclusion_select_page_names "select first_names, last_name, exc.*
from static_page_index_exclusion exc, users u
where u.user_id = exc.creation_user
and exc.exclusion_pattern_id = $exclusion_pattern_id"

doc_return  200 text/html "[ad_admin_header "One Exclusion Pattern"]

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
<li><a href=\"test-pattern?[export_url_vars exclusion_pattern_id]\">test this pattern</a>
<p>
<li><a href=\"delete-one?[export_url_vars exclusion_pattern_id]\">delete this pattern</a>
</ul>

[ad_admin_footer]
"

db_release_unused_handles