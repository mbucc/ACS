ad_page_contract {
    Main user group administration page.
    @cvs-id index.tcl,v 3.1.6.6 2000/09/22 01:36:15 kevin Exp
    # 3.4 upgrade coded by teadams on July 9th
} {}


append return_string "[ad_admin_header "User Group Administration"]

<h2>User Group Administration</h2>

[ad_admin_context_bar "User Groups"]

<hr>

Currently, the system is able to handle the following types of groups:

<ul>"


db_foreach user_group_types "select ugt.group_type, ugt.pretty_name, count(ug.group_id) as n_groups
from user_group_types ugt, user_groups ug
where ugt.group_type = ug.group_type(+)
group by ugt.group_type, ugt.pretty_name
order by upper(ugt.pretty_name)" {
    append return_string "<li><a href=\"group-type?group_type=[ns_urlencode $group_type]\">$pretty_name</a> (number of groups defined: $n_groups)\n"
} if_no_rows {
    append return_string "no group types currently defined"
}

append return_string "<p>

<li><a href=\"group-type-new\">Define a new group type</a>

</ul>

[ad_admin_footer]
"

doc_return  200 text/html  $return_string