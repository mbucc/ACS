ad_page_contract {
    @cvs-id users-all.tcl,v 3.2.6.3.2.3 2000/09/22 01:36:29 kevin Exp
} {
    order_by:notnull
}


append whole_page "[ad_admin_header "Candidates for Merger"]

<h2>Candidates for Merger</h2>

ordered by $order_by

<hr>

<ul>
"



if { $order_by == "email" } {
    set order_by_clause "upper(email), upper(last_name), upper(first_names)"
} elseif { $order_by == "first_names" } {
    set order_by_clause "upper(first_names), upper(last_name), upper(email)"
} else {
    set order_by_clause "upper(last_name), upper(first_names), upper(email)"
}

set sql "select user_id, first_names, last_name, email
from users 
order by $order_by_clause"

set last_id ""
db_foreach merge_candidates $sql {
    append whole_page "<li><a target=new_window href=\"../one?user_id=$user_id\">"
    if { $order_by == "email" } {
	append whole_page "$email</a> ($first_names $last_name)"
    } else {
	append whole_page "$first_names $last_name</a> ($email)"	
    }
    if ![empty_string_p $last_id] {
	append whole_page " <a target=merge_window href=\"merge?u1=$last_id&u2=$user_id\"><font size=-1>merge with above</font></a>\n"
    }
    set last_id $user_id
}

append whole_page "

</ul>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
