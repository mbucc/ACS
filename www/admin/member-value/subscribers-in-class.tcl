# $Id: subscribers-in-class.tcl,v 3.0 2000/02/06 03:25:05 ron Exp $
set_the_usual_form_variables

# subscriber_class

ReturnHeaders

ns_write "[ad_no_menu_header "$subscriber_class subscribers"]

<h2>$subscriber_class subscribers</h2>

in <a href=\"index.tcl\">[ad_system_name]</a>

<hr>

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select u.user_id, u.first_names, u.last_name, u.email
from users u, users_payment up
where u.user_id = up.user_id
and up.subscriber_class = '$QQsubscriber_class'
order by upper(u.last_name), upper(u.first_names)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"../user-home.tcl?user_id=$user_id\">$first_names $last_name</a> ($email)\n"
}

ns_write "
</ul>

[ad_no_menu_footer]
"
