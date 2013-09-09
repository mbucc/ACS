ad_page_contract {
    delete-one.tcl,v 3.2.2.4 2000/09/22 01:36:10 kevin Exp
    
    /admin/static/exclusion/delete-one.tcl
    by jsc@arsdigita.com on November 6, 1999
    Confirmation page for pattern deletion.
} {
    exclusion_pattern_id:integer
}

db_1row static_exclusion_get_names "select first_names, last_name, exc.*
from static_page_index_exclusion exc, users u
where u.user_id = exc.creation_user
and exc.exclusion_pattern_id = $exclusion_pattern_id"



doc_return  200 text/html "[ad_admin_header "Delete Pattern"]

<h2>Delete Pattern</h2>

[ad_admin_context_bar [list "../index.tcl" "Static Content"] [list "one-pattern.tcl?[export_url_vars exclusion_pattern_id]" "One Exclusion Pattern"] "Delete Pattern"]

<hr>

<form action=\"delete-one-2\">
[export_form_vars exclusion_pattern_id]

<blockquote>
<table border=0 width=60%>
<tr><th>Field</th><td>$match_field</td></tr>
<tr><th>Pattern Type</th><td>$like_or_regexp</td></tr>
<tr><th>Pattern</th><td>$pattern</td></tr>
<tr><th>Comment</th><td>$pattern_comment</td></tr>
<tr><th>Creation User</th><td>$first_names $last_name</td></tr>
<tr><th>Creation Date</th><td>$creation_date</td></tr>
<tr><td colspan=2 align=center><input type=submit value=\"Delete This Pattern\"></td></tr>
</table>
</blockquote>

</form>

[ad_admin_footer]
"
