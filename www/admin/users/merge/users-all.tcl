# $Id: users-all.tcl,v 3.1 2000/03/09 00:01:39 scott Exp $
set_the_usual_form_variables

# order_by

append whole_page "[ad_admin_header "Candidates for Merger"]

<h2>Candidates for Merger</h2>

ordered by $order_by

<hr>

<ul>

"

set db [ns_db gethandle]

if { $order_by == "email" } {
    set order_by_clause "upper(email), upper(last_name), upper(first_names)"
} elseif { $order_by == "first_names" } {
    set order_by_clause "upper(first_names), upper(last_name), upper(email)"
} else {
    set order_by_clause "upper(last_name), upper(first_names), upper(email)"
}

set selection [ns_db select $db "select user_id, first_names, last_name, email
from users 
order by $order_by_clause"]

set last_id ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append whole_page "<li><a target=new_window href=\"../one.tcl?user_id=$user_id\">"
    if { $order_by == "email" } {
	append whole_page "$email</a> ($first_names $last_name)"
    } else {
	append whole_page "$first_names $last_name</a> ($email)"	
    }
    if ![empty_string_p $last_id] {
	append whole_page " <a target=merge_window href=\"merge.tcl?u1=$last_id&u2=$user_id\"><font size=-1>merge with above</font></a>\n"
    }
    set last_id $user_id
}

append whole_page "

</ul>

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
