# $Id: detail-function-or-procedure.tcl,v 3.0 2000/02/06 03:25:25 ron Exp $
set_form_variables

# object_name, owner 

set page_name $object_name

set db [cassandracle_gethandle]

set the_query "
select
  text
from
  DBA_SOURCE
where
  name='$object_name' and owner='$owner'
order by
  line"

set description [join [database_to_tcl_list $db $the_query]]

ReturnHeaders
ns_write "

[ad_admin_header "Space usage"]

<h2>Space usage</h2>


[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] [list \"/admin/monitoring/cassandracle/users/\" "Users"] [list "/admin/monitoring/cassandracle/users/user-owned-objects.tcl" "Objects" ] [list "/admin/monitoring/cassandracle/users/one-user-specific-objects.tcl?owner=ACS&object_type=FUNCTION" "Functions"] "One"]

<hr>
<p>
<blockquote><pre>$description</pre></blockquote>
<p>
The SQL:
<pre>
$the_query
</pre>
[ad_admin_footer]
"