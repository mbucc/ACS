# /admin/monitoring/configuration/index.tcl

ad_page_contract { 
    Displays some basic information about this installation of AOLServer:
    IP Address, System Name, and System Owner.

    @cvs-id index.tcl,v 3.1.2.4 2000/10/23 21:25:40 ashah Exp
} {
}

doc_return  200 text/html "[ad_admin_header "[ad_system_name] Configuration"]

<h2>[ad_system_name] Configuration</h2>

[ad_admin_context_bar  [list "/admin/monitoring/index" "Monitoring"] "Configuration"]

<hr>
<ul>
<li>IP Address: [ns_config ns/server/[ns_info server]/module/nssock address "Could not find IP"]
<li>System Name: [ad_parameter SystemName]
<li>System Owner: <a href=mailto:[ad_parameter SystemOwner]>[ad_parameter SystemOwner]</a>
</ul>

[ad_admin_footer]
"
