# $Id: subscriber-class.tcl,v 3.0 2000/02/06 03:25:04 ron Exp $
set_the_usual_form_variables

# subscriber_class

ReturnHeaders

ns_write "[ad_no_menu_header "$subscriber_class"]

<h2>$subscriber_class</h2>

a subscription class in <a href=\"index.tcl\">[ad_system_name]</a>

<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from mv_monthly_rates where subscriber_class = '$QQsubscriber_class'"]

set_variables_after_query

ns_write "<li><form method=get action=\"subscriber-class-new-rate.tcl\">
[export_form_vars subscriber_class]
Set rate:
<input type=text size=7 name=rate value=\"$rate\">
</form>
<li>
<form method=get action=\"subscriber-class-new-currency.tcl\">
[export_form_vars subscriber_class]
Set currency:
<input type=text size=7 name=currency value=\"$currency\">
</form>

</ul>

If you decide that this subscriber class isn't working anymore, you can 
<a href=\"subscriber-class-delete.tcl?subscriber_class=[ns_urlencode $subscriber_class]\">delete it and move all the subscribers into another class</a>.

[ad_no_menu_footer]
"
