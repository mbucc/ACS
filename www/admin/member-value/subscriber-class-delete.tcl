# $Id: subscriber-class-delete.tcl,v 3.0 2000/02/06 03:25:01 ron Exp $
set_the_usual_form_variables

# subscriber_class

ReturnHeaders

ns_write "[ad_no_menu_header "Delete $subscriber_class"]

<h2>Delete subscriber class $subscriber_class</h2>

from <a href=\"index.tcl\">[ad_system_name]</a>

<hr>

<form method=GET action=\"subscriber-class-delete-2.tcl\">
[export_form_vars subscriber_class]

<ul>
<li>Number of subscribers presently in this class:

"

set db [ns_db gethandle]
set n_subscribers [database_to_tcl_string $db "select count(*) from users_payment where subscriber_class = '$QQsubscriber_class'"]

ns_write "$n_subscribers"

ns_write "<li>subscriber class into which to move the above folks:
<select name=new_subscriber_class>
[db_html_select_options $db "select subscriber_class 
from mv_monthly_rates
where subscriber_class <> '$QQsubscriber_class'
order by rate"]
</select>
</ul>

<center>
<input type=submit value=\"Yes, I'm absolutely sure that I want to delete $subscriber_class\">
</center>
</form>

[ad_no_menu_footer]
"
