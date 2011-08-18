# $Id: test-pattern.tcl,v 3.0 2000/02/06 03:30:48 ron Exp $
# 
# /admin/static/exclusion/one-pattern.tcl
#
# by jsc@arsdigita.com on November 6, 1999
#
# Show all static pages which would be affected by this comment.
#


set_form_variables
# exclusion_pattern_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select match_field, like_or_regexp, pattern
from static_page_index_exclusion
where exclusion_pattern_id = $exclusion_pattern_id"]

set_variables_after_query

if { $like_or_regexp != "like" } {
    ad_return_error "Not implemented" "$like_or_regexp patterns not yet implemented."
    return
}

set selection [ns_db select $db "select url_stub, page_title, index_p
from static_pages
where $match_field like '$pattern'
order by index_p, url_stub"]

set excluded_results ""
set included_results ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $index_p == "t" } {
	append included_results "<li>$url_stub ($page_title)\n"
    } else {
	append excluded_results "<li>$url_stub ($page_title)\n"
    }
}

if { [empty_string_p $included_results] } {
    set included_results "None"
}

if { [empty_string_p $excluded_results] } {
    set excluded_results "None"
}

ns_return 200 text/html "[ad_admin_header "Pattern Test"]

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


