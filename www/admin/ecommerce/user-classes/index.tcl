# $Id: index.tcl,v 3.0 2000/02/06 03:22:00 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "User Class Administration"]

<h2>User Class Administration</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "User Classes"]

<hr>

<h3>Current User Classes</h3>

<ul>
"

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

set selection [ns_db select $db "select 
  ec_user_classes.user_class_id, 
  ec_user_classes.user_class_name,
  count(user_id) as n_users
from ec_user_classes, ec_user_class_user_map m
where ec_user_classes.user_class_id = m.user_class_id(+)
group by ec_user_classes.user_class_id, ec_user_classes.user_class_name
order by user_class_name"]

set user_class_counter 0
while { [ns_db getrow $db $selection] } {
    incr user_class_counter
    set_variables_after_query
    ns_write "<li><a href=\"one.tcl?[export_url_vars user_class_id user_class_name]\">$user_class_name</a> <font size=-1>($n_users user[ec_decode $n_users "1" "" "s"]"

    if { [ad_parameter UserClassApproveP ecommerce] } {
	set n_approved_users [database_to_tcl_string $db_sub "select 
count(*) as approved_n_users
from ec_user_class_user_map
where user_class_approved_p = 't'
and user_class_id=$user_class_id"]

	ns_write " , $n_approved_users approved user[ec_decode $n_approved_users "1" "" "s"]"
    }
    ns_write ")</font>\n"
}

if { $user_class_counter == 0 } {
    ns_write "You haven't set up any user classes.\n"
}

# For audit tables
set table_names_and_id_column [list ec_user_classes ec_user_classes_audit user_class_id]

ns_write "
</ul>

<p>

<h3>Actions</h3>

<ul>
<li><a href=\"/admin/ecommerce/audit-tables.tcl?[export_url_vars table_names_and_id_column]\">Audit All User Classes</a>
</ul>

<p>

<h3>Add a New User Class</h3>

<ul>

<form method=post action=add.tcl>
Name: <input type=text name=user_class_name size=30>
<input type=submit value=\"Add\">
</form>

</ul>

[ad_admin_footer]
"
