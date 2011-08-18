# $Id: one-user-specific-objects.tcl,v 3.0 2000/02/06 03:25:38 ron Exp $
# called from ./user-owned-objects.tcl

set_form_variables

# check arguments -----------------------------------------------------

# $object_type   REQUIRED ARGUMENT
if { ![info exists object_type] } {
    ns_returnerror 500 "Missing \$object_type"
    return
}
# $owner   REQUIRED ARGUMENT
if { ![info exists owner] } {
    ns_returnerror 500 "Missing \$owner"
    return
}

# $order   OPTIONAL ARGUMENT, BUT NEED TO SET DEFAULT
if { ![info exists order] } {
    set order "object_name" 
}

# $order   TWO VALUES ONLY ARE VALID
if { [string compare $order "object_name"] != 0 && [string compare $order "last_ddl_time"] != 0 } {
    ns_returnerror 500 "Invalid value of \$order: $order, Valid values include only  \"object_name\" and \"last_ddl_time\" "
    return
}

# $order - If order is "last_ddl_time", then order descending
if { [string compare $order "last_ddl_time"]==0 } {
    append order " DESC"
}



# arguments OK, start building page ----------------------------------------

set page_name "Objects of type $object_type owned by $owner"
ReturnHeaders
set db [cassandracle_gethandle]

ns_write "

[ad_admin_header "$page_name"]

<h2>$page_name</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] [list \"/admin/monitoring/cassandracle/users/\" "Users"] [list "/admin/monitoring/cassandracle/users/user-owned-objects.tcl" "Objects" ] "One Object Type"]

<!-- version 1.1, 1999-10-20, Dave Abercrombie -->
<hr>
"

# set $href variable used for linking from object_name column of table (after substitution)
if {$object_type=="FUNCTION"||$object_type=="PROCEDURE"} {
    set href "<a href=\"../objects/detail-function-or-procedure.tcl?object_name=\[lindex \$row 0]&owner=$owner\">\[lindex \$row 0]</a>"    
} elseif  {$object_type=="TABLE"||$object_type=="VIEW"} {
    set href "<a href=\"../objects/describe-table.tcl?object_name=${owner}.\[lindex \$row 0]\">\[lindex \$row 0]</a>"    
} else {
    set href "\[lindex \$row 0\]"
}


# build the SQL and write out as comment
set the_query "
-- /users/one-user-specific-objects.tcl
select
    do.object_name, 
    do.created, 
    do.last_ddl_time, 
    lower(do.status) as status
from
    dba_objects do
where
    do.owner='$owner' 
and do.object_type='$object_type'
order by
  $order
"
ns_write "<!-- $the_query -->"

# write the table headers
# put sort links in as appropriate
# headers depend on sort order, I use a switch for future flexibility
switch -exact -- $order {
    "object_name" {
	set object_name_header "Object Name"
	set last_ddl_time_header "<a href=\"one-user-specific-objects.tcl?owner=$owner&object_type=$object_type&order=last_ddl_time\">Last DDL</a>"
    }
    "last_ddl_time DESC" {
	set object_name_header "<a href=\"one-user-specific-objects.tcl?owner=$owner&object_type=$object_type&order=object_name\">Object Name</a>"
	set last_ddl_time_header "Last DDL"
    }
}

ns_write "
<table cellpadding=3 border=1>
<tr>
  <th>$object_name_header</th>
  <th>Created</th>
  <th>$last_ddl_time_header</th>
  <th>Status</th>
</tr>
"

# run query
set object_ownership_info [database_to_tcl_list_list $db $the_query]

# output rows
if {[llength $object_ownership_info]==0} {
    ns_write "<tr><td>No objects found!</td></tr>"
} else {
    foreach row $object_ownership_info {
	ns_write "
        <tr>
	  <td>[subst $href] &nbsp;</td>
	  <td align=right>[lindex $row 1]</td>
	  <td align=right>[lindex $row 2]</td>
	  <td>[lindex $row 3]</td>
	</tr>\n"
    }
}

# close up shop
ns_write "</table>
<hr>
<H4>More information:</h4>
<p>See Oracle documentation about view <a target=second href=\"http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch2.htm#51392\">dba_objects</a> on which this page is based.</p>
[ad_admin_footer]
"