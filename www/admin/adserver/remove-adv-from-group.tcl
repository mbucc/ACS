# /www/admin/adserver/remove-adv-from-group.tcl

ad_page_contract {
    @param group_key:notnull
    @param adv_key:notnull

    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id remove-adv-from-group.tcl,v 3.1.6.5 2000/11/20 23:55:20 ron Exp
} {
    group_key:notnull
    adv_key:notnull
}

set pretty_name [db_string pretty_name "
select pretty_name
from   adv_groups
where  group_key = :group_key"]

doc_return 200 text/html "
[ad_admin_header "Confirm removal of $adv_key"]

<h2>Confirm</h2>

[ad_admin_context_bar [list "" "AdServer"] "confirm removal from group"]

<hr>

<p>This won't remove the ad from the system.  You're only deleting the 
association between the group $group_key ($pretty_name) and this ad.  

<p>

<form method=get action=\"remove-adv-from-group-2\">

[export_form_vars group_key adv_key]

<center>
<input type=submit value=\"Confirm Removal\">
</center>
</form>

[ad_admin_footer]
"


