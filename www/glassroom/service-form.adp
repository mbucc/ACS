<%
# host-form.adp -- an included file for service-edit.adp and service-add.adp which
#                  shares this form between those two pages
#
# required arguments - the text for the "submit button" and the action
#                      for the form


if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to host-form.adp.  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action

# create a set of hosts

set select_sql "select host_id, hostname from glassroom_hosts order by hostname"

set selection [ns_db select $db $select_sql]

set hosts ""

lappend hosts [list "" "None"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend hosts [list $host_id $hostname]
}

ns_log notice "FNORD $hosts"


# make sure these variables exist so we don't generate lots of errors
# accessing unknown variables below

if { ![info exists web_service_host] } {
    set web_service_host ""
}

if { ![info exists rdbms_host] } {
    set rdbms_host ""
}

if { ![info exists dns_primary_host] } {
    set dns_primary_host ""
}

if { ![info exists dns_secondary_host] } {
    set dns_secondary_host ""
}

if { ![info exists disaster_host] } {
    set disaster_host ""
}


%>

<%=[glassroom_form_action "$form_action" ]%>

<%
if { [info exists service_name] } {
    set old_service_name $service_name
    ns_puts "[export_form_vars service_name old_service_name]\n"
}
%>


<table>

<tr>
  <td align=right> Service Name:
  <td>             <input type=text size=30 name=service_name <%= [export_form_value service_name] %>>
</tr>

<tr>
  <td align=right> WebService Host:
  <td>             <select name=web_service_host>
<%
foreach host $hosts {
    set host_id [lindex $host 0]
    set host_name [lindex $host 1]
    if { [string compare $host_id $web_service_host] == 0 } {
	ns_puts "                     <option value=\"$host_id\" selected> $host_name"
    } else {
	ns_puts "                     <option value=\"$host_id\"> $host_name"
    }
}
%>
                   </select>
</tr>


<tr>
  <td align=right> RDBMS Host:
  <td>             <select name=rdbms_host>
<%
foreach host $hosts {
    set host_id [lindex $host 0]
    set host_name [lindex $host 1]
    if { [string compare $host_id $rdbms_host] == 0 } {
	ns_puts "                     <option value=\"$host_id\" selected> $host_name"
    } else {
	ns_puts "                     <option value=\"$host_id\"> $host_name"
    }
}
%>
                   </select>
</tr>


<tr>
  <td align=right> DNS Primary Host:
  <td>             <select name=dns_primary_host>
<%
foreach host $hosts {
    set host_id [lindex $host 0]
    set host_name [lindex $host 1]
    if { [string compare $host_id $dns_primary_host] == 0 } {
	ns_puts "                     <option value=\"$host_id\" selected> $host_name"
    } else {
	ns_puts "                     <option value=\"$host_id\"> $host_name"
    }
}
%>
                   </select>
</tr>


<tr>
  <td align=right> DNS Secondary Host:
  <td>             <select name=dns_secondary_host>
<%
foreach host $hosts {
    set host_id [lindex $host 0]
    set host_name [lindex $host 1]
    if { [string compare $host_id $dns_secondary_host] == 0 } {
	ns_puts "                     <option value=\"$host_id\" selected> $host_name"
    } else {
	ns_puts "                     <option value=\"$host_id\"> $host_name"
    }
}
%>
                   </select>
</tr>

<tr>
  <td align=right> Disaster Host:
  <td>             <select name=disaster_host>
<%
foreach host $hosts {
    set host_id [lindex $host 0]
    set host_name [lindex $host 1]
    if { [string compare $host_id $disaster_host] == 0 } {
	ns_puts "                     <option value=\"$host_id\" selected> $host_name"
    } else {
	ns_puts "                     <option value=\"$host_id\"> $host_name"
    }
}
%>
                   </select>
</tr>

</table>


<p>
  
<%=[glassroom_submit_button "$submit_button_text" ]%>


</form>

