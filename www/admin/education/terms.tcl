#
# /www/admin/education/terms.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page lists all of the terms in the system
#

# not expecting anything

set db [ns_db gethandle]

set return_string "
[ad_admin_header "[ad_system_name] Administration - Terms"]
<h2>Terms</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] "Terms"]

<hr>
<blockquote>
<table>
<tr>
<td>
<b>Term Name</b>
</td>

<td>
<b>Start Date</b>
</td>

<td>
<b>End Date</b>
</td>

<td>
<b>Number Of Classes</b>
</td>
</tr>
"

# lets list all of the terms that have been entered and lets also give
# the option of adding a new term.  Each term links to a term.tcl page
# that tells the dates it is good for, classes for the term, etc.

set selection [ns_db select $db "select count(class_id) as n_classes,
                                        edu_terms.term_id, 
                                        edu_terms.term_name, 
                                        edu_terms.start_date, 
                                        edu_terms.end_date 
                                   from edu_terms, 
                                        edu_classes 
                                  where edu_terms.term_id = edu_classes.term_id(+) 
                               group by edu_terms.term_id, edu_terms.term_name, edu_terms.start_date, edu_terms.end_date
                               order by edu_terms.end_date desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "<tr>
    <td align=left><a href=\"term-one.tcl?term_id=$term_id\">$term_name</a></td>
    <td> [util_AnsiDatetoPrettyDate $start_date] </td>
    <td> [util_AnsiDatetoPrettyDate $end_date] </td>
    "
    if {$n_classes == 0} {
	append return_string "<td align=center>$n_classes</td></tr>"
    } else {
	append return_string "
	<td align=center><a href=classes.tcl?term_id=$term_id>$n_classes</a> </td>
	</tr>
	"
    }
}

append return_string "
</table>

<br>
<a href=term-add.tcl>Add a Term</a>
</blockquote>
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string








