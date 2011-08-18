# $Id: query-new.tcl,v 3.0.4.1 2000/04/28 15:09:59 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode /dw/query-new.tcl]
   return
}

ReturnHeaders

ns_write "
[ad_header "Define New Query"]

<h2>Define New Query</h2>

for <a href=index.tcl>the query section</a> of [dw_system_name]

<hr>

<form method=POST action=\"query-new-2.tcl\">
<table>
<tr><th>Query Name<td><input type=text name=query_name size=30>
</table>

<br>

<center>
<input type=submit value=\"Define\">
</center>
</form>


[ad_footer]
"
