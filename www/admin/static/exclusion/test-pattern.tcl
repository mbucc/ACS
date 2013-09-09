ad_page_contract {
    test-pattern.tcl,v 3.1.2.4 2000/09/22 01:36:10 kevin Exp
    
    /admin/static/exclusion/one-pattern.tcl
    by jsc@arsdigita.com on November 6, 1999
    Show all static pages which would be affected by this comment.
} {
    exclusion_pattern_id:integer
}

db_1row static_exclusion_get_match_field "select match_field, 
like_or_regexp, pattern
from static_page_index_exclusion
where exclusion_pattern_id = $exclusion_pattern_id"

if { $like_or_regexp != "like" } {
    ad_return_error "Not implemented" "$like_or_regexp patterns not yet implemented."
    return
}

set included_results ""
set excluded_results ""

db_foreach static_exclusion_get_url_stub "select url_stub, page_title, index_p
from static_pages
where :match_field like '$pattern'
order by index_p, url_stub" {
    if { $index_p == "t" } {
	append included_results "<li>$url_stub ($page_title)\n"
    } else {
	append excluded_results "<li>$url_stub ($page_title)\n"
    }
} if_no_rows {
    set included_results "None"
    set excluded_results "None"
}

doc_return  200 text/html "[ad_admin_header "Pattern Test"]

<h2>Pattern Test</h2>

[ad_admin_context_bar [list "../index.tcl" "Static Content"] [list "one-pattern.tcl?[export_url_vars exclusion_pattern_id]" "One Exclusion Pattern"] "Pattern Test"]

<hr>

Pages matching \"$pattern\" on $match_field using [string toupper $like_or_regexp] match:

<h3>Already Excluded Pages</h3>
<ul>
$excluded_results
</ul>

<h3>Pages That Would Be Excluded</h3>
<ul>
$included_results
</ul>

[ad_admin_footer]
"
db_release_unused_handles


