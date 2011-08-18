# $Id: subscriber-class-delete-2.tcl,v 3.0 2000/02/06 03:25:00 ron Exp $
set_the_usual_form_variables

# subscriber_class, new_subscriber_class

set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_no_menu_header "Deleting $subscriber_class"]

<h2>Deleting $subscriber_class</h2>

from <a href=\"index.tcl\">[ad_system_name]</a>

<hr>

Moving all the old subscribers to $new_subscriber_class ...

"

ns_db dml $db "begin transaction"


ns_db dml $db "update users_payment set subscriber_class = '$QQnew_subscriber_class' where subscriber_class = '$QQsubscriber_class'"

ns_write " .. done.  Now deleting the subscriber class from mv_monthly_rates... " 

ns_db dml $db "delete from mv_monthly_rates where subscriber_class = '$QQsubscriber_class'"

ns_db dml $db "end transaction"

ns_write " ... done.

[ad_no_menu_footer]
"
