#
# /www/admin/education/term-one.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays the information about one term
#

ad_page_variables {
    term_id
}


if {[empty_string_p $term_id]} {
    ad_return_complaint 1 "<li>You must provide a valid term_id"
    return
}


set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select term_name, start_date, end_date from edu_terms where term_id = $term_id"]

if { $selection == 0 } {
    ad_return_complaint 1 "<li>The term id that you provided does not correspond to any term."
    return
} else {
    set_variables_after_query
}

if {[empty_string_p $start_date]} {
    set actual_start_date "No Start Date Specified"
} else {
    set actual_start_date [util_AnsiDatetoPrettyDate $start_date]
}

if {[empty_string_p $end_date]} {
    set actual_end_date "No End Date Specified"
} else {
    set actual_end_date [util_AnsiDatetoPrettyDate $end_date]
}



set return_string "
[ad_admin_header "[ad_system_name] Administration - Terms"]
<h2>One Term - $term_name</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] [list terms.tcl "Terms"] "One Term"]

<hr>
<blockquote>

<li>Term Name: $term_name
<li>Start Date: $actual_start_date
<li>End Date: $actual_end_date
<br>
(<a href=\"term-edit.tcl?[export_url_vars start_date end_date term_id term_name]\">edit</a>)
<br><br>
<h3>Classes</h3>
<ul>
"

set selection [ns_db select $db "select class_id, class_name from edu_classes where term_id = $term_id"]

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr count
    append return_string "<li><a href=\"/education/util/group-login.tcl?group_id=$class_id&group_type=edu_class&return_url=[ns_urlencode [edu_url]class/one.tcl]\">$class_name</a>
    [ad_space 2] \[ <a href=\"/education/util/group-login.tcl?group_id=$class_id&group_type=edu_class&return_url=[ns_urlencode [edu_url]class/admin/]\">admin page</a> \]"
}

if {$count == 0} {
    append return_string "There are no clsses signed up for this term."
}

append return_string "
</ul>
</blockquote>
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string








