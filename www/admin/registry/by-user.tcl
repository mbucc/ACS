# www/admin/registry/by-user.tcl

ad_page_contract {
    @cvs-id by-user.tcl,v 3.1.6.3 2000/09/22 01:36:00 kevin Exp
} {    
}


proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}


set sql "select 
 u.first_names, u.last_name, u.user_id, count(*) count, max(posted) last_posted
 FROM stolen_registry s, users u
where u.user_id = s.user_id
group by u.first_names, u.last_name, u.user_id
order by count desc"

set html "[ad_admin_header "Stolen Equipment Registry Users"]

<h2>Stolen Equipment Registry Users</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "Entries"]

<hr>

 \[ <a href=\"by-date\">View all entries sorted by date</a> \]

<ul>
"

db_foreach registry_list $sql {
    append html "<li><a href=\"search-one-user?user_id=$user_id\">$first_names $last_name</a> ($count, most recent on [util_AnsiDatetoPrettyDate $last_posted])"

}

append html "</ul>\n"
append html "
or 

<form method=post action=search-pls>
Search by full text query:  <input type=text name=query_string size=40>
</form>
<p>
Note: this searches through names, email addresses, stories, manufacturers, models, and 
serial numbers.

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
