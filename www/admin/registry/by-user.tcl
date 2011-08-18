# $Id: by-user.tcl,v 3.0 2000/02/06 03:27:57 ron Exp $
proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set db [ns_db gethandle]

set selection [ns_db select $db "select 
 u.first_names, u.last_name, u.user_id, count(*) count, max(posted) last_posted
 FROM stolen_registry s, users u
where u.user_id = s.user_id
group by u.first_names, u.last_name, u.user_id
order by count desc"]

ReturnHeaders

ns_write "[ad_admin_header "Stolen Equipment Registry Users"]

<h2>Stolen Equipment Registry Users</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "Entries"]

<hr>

 \[ <a href=\"by-date.tcl\">View all entries sorted by date</a> \]

<ul>
"

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    ns_write "<li><a href=\"search-one-user.tcl?user_id=$user_id\">$first_names $last_name</a> ($count, most recent on [util_AnsiDatetoPrettyDate $last_posted])"

}

ns_write "</ul>\n"

ns_write "
or 

<form method=post action=search-pls.tcl>
Search by full text query:  <input type=text name=query_string size=40>
</form>
<p>
Note: this searches through names, email addresses, stories, manufacturers, models, and 
serial numbers.

[ad_admin_footer]
"
