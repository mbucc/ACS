# $Id: remove-adv-from-group.tcl,v 3.0 2000/02/06 02:46:10 ron Exp $
set_the_usual_form_variables

# group_key, adv_key

set db [ns_db gethandle]

ns_return 200 text/html "[ad_admin_header "Confirm removal of $adv_key"]

<h2>Confirm</h2>

the removal of <a href=\"one-adv.tcl?[export_url_vars adv_key]\">$adv_key</a> 
from <a href=\"one-adv-group.tcl?[export_url_vars group_key]\">$group_key</a>

<hr>

This won't remove the ad from the system.  You're only deleting the
association between the group $group_key ([database_to_tcl_string $db "select pretty_name from adv_groups where group_key = '$QQgroup_key'"]) and this ad. 

<p>

<form method=get action=\"remove-adv-from-group-2.tcl\">

[export_form_vars group_key adv_key]

<center>
<input type=submit value=\"Confirm Removal\">
</center>
</form>

[ad_admin_footer]
"
