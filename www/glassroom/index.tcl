# $Id: index.tcl,v 3.0.4.1 2000/04/28 15:10:43 carsten Exp $
# index.tcl for /glassroom -- primary page for accessing the GlassRoom
#               module.  displays current alerts, as well as look at
#               existing information, and add logbook entries


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
	ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
	return
}


# emit the page contents

set page_title [ad_parameter SystemName glassroom "Glass Room"]

ReturnHeaders

ns_write "[ad_header $page_title]

<h2>$page_title</h2>

from [ad_site_home_link]

<hr>

"


set db [ns_db gethandle]


# important alerts go here


ns_write "<h3>Alerts</h3>
<ul>"

set alerts_p 0



# see if any certs (with retsin!)  have expired

set cert_expire_threshold [ad_parameter CertExpireMonthWarning glassroom 2]

set count [database_to_tcl_string $db "select count(*) from glassroom_certificates where trunc(months_between(expires,sysdate),2) < $cert_expire_threshold"]

if { $count > 0 } {
    
    set alerts_p 1

    set select_sql "
    select hostname,  expires, cert_id,
           trunc(months_between(expires,sysdate), 2) as expire_months
      from glassroom_certificates
     where trunc(months_between(expires,sysdate), 2) < $cert_expire_threshold
     order by hostname
    "
    set selection [ns_db select $db $select_sql]
    
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "    <li> <a href=\"cert-view.tcl?[export_url_vars cert_id]\">$hostname</a>"
	if { $expire_months < 0} {
	    ns_write "    <font color=red>Certificate has <blink>expired</blink></font>"
	} elseif { $expire_months < $cert_expire_threshold } {
	    ns_write "    <font color=red>Certificate will soon expire</font>"
	}
    }
}


# see if any domains  have expired

set domain_expire_threshold [ad_parameter DomainExpireMonthWarning glassroom 2]

set count [database_to_tcl_string $db "select count(*) from glassroom_domains where trunc(months_between(expires,sysdate),2) < $domain_expire_threshold"]

if { $count > 0 } {
    
    set alerts_p 1

    set select_sql "
    select domain_name,
           trunc(months_between(expires,sysdate), 2) as expire_months
      from glassroom_domains
     where trunc(months_between(expires,sysdate), 2) < $domain_expire_threshold
     order by domain_name
    "
    set selection [ns_db select $db $select_sql]
    
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "    <li> <a href=\"domain-view.tcl?[export_url_vars domain_name]\">$domain_name</a>"
	if { $expire_months < 0} {
	    ns_write "    <font color=red>Domain has <blink>expired</blink></font>"
	} elseif { $expire_months < $domain_expire_threshold } {
	    ns_write "    <font color=red>Domain will soon expire</font>"
	}
    }
}


if { !$alerts_p } {
    ns_write "<li> no alerts at this time"
}

ns_write "</ul>"




# logbook stuff

ns_write "<br><br><br> <h3>Logbook</h3>
<ul>"

set select_sql "
select procedure_name, count(*) as count
  from glassroom_logbook
 group by procedure_name
 order by procedure_name"

set selection [ns_db select $db $select_sql]

set logbook_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $count == 1 } {
	ns_write "    <li> <a href=\"logbook-view.tcl?[export_url_vars procedure_name]\">$procedure_name</a> (1 entry)"
    } else {
	ns_write "    <li> <a href=\"logbook-view.tcl?[export_url_vars procedure_name]\">$procedure_name</a> ($count entries)"
    }

    incr logbook_count
}

if { $logbook_count == 0 } {
    ns_write "    <li> No logbook entries found.  Would you like to <a href=\"logbook-add.adp\">add one</a>?\n</ul>"
} else {
    ns_write "</ul>\nOr <a href=\"logbook-add.adp\">add a new logbook entry</a>?\n"
}


# Software module and release stuff

# glassroom_modules.  module_id, module_name, current_version

ns_write "<br><br><br> <h3>Software Modules</h3>
<ul>"

set select_sql "
select module_id, module_name, current_version
  from glassroom_modules
 order by module_name
"

set selection [ns_db select $db $select_sql]

set module_count 0

set db2 [ns_db gethandle subquery]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "    <li> <a href=\"module-view.tcl?[export_url_vars module_id]\">$module_name</a> $current_version"
    
    set count [database_to_tcl_string $db2 "select count(*) from glassroom_releases where module_id = $module_id"]
    if { $count > 0 } {
	ns_write "      <ul>"

	set sub_select_sql "select release_id, release_name, release_date, anticipated_release_date from glassroom_releases where module_id = $module_id order by release_name"

	set sub_selection [ns_db select $db2 $sub_select_sql]

	while { [ns_db getrow $db2 $sub_selection] } {
	    set_variables_after_subquery
	    #!!! do something with release_date and anticipated_release_date, such as print 'released on xxxxx', or 'antcipated to be released on xxxx'
	    ns_write "      <li> <a href=\"release-view.tcl?[export_url_vars release_id]\">$release_name</a>"
	}

	ns_write "      </ul>"
    }
    incr module_count
}

ns_db releasehandle $db2

if { $module_count == 0 } {
    ns_write "    <li> No software modules found.  Would you like to <a href=\"module-add.adp\">add one</a>?\n</ul>"
} else {
    ns_write "    </ul>\nOr <a href=\"module-add.adp\">add a new software module</a> or <a href=\"release-add.adp\">add a new release to a module</a>?\n"
}



# procedure stuff

ns_write "<br><br><br> <h3>Procedures</h3>
<ul>"

set select_sql "
select procedure_name
  from glassroom_procedures
 order by procedure_name"

set selection [ns_db select $db $select_sql]

set procedure_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    ns_write "    <li> <a href=\"procedure-view.tcl?[export_url_vars procedure_name]\">$procedure_name</a>"

    incr procedure_count
}

if { $procedure_count == 0 } {
    ns_write "    <li> No procedures found.  Would you like to <a href=\"procedure-add.adp\">add one</a>?\n</ul>"
} else {
    ns_write "</ul>\nOr <a href=\"procedure-add.adp\">add a new procedure</a>?\n"
}



# Service stuff


ns_write "
<br><br><br><h3>Services</h3>
<ul>"

set select_sql "
select service_name
  from glassroom_services
 order by service_name
"

set selection [ns_db select $db $select_sql]

set service_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "    <li> <a href=\"service-view.tcl?[export_url_vars service_name]\">$service_name</a>"
    incr service_count
}

if { $service_count == 0 } {
    ns_write "    <li> No services found.  Would you like to <a href=\"service-add.adp\">add one</a>?\n</ul>"
} else {
    ns_write "</ul>\nOr <a href=\"service-add.adp\">add a new service</a>?\n"
}



# Host stuff


ns_write "
<br><br><br><h3>Hosts</h3>
<ul>"

set select_sql "
select hostname, host_id 
  from glassroom_hosts
 order by hostname
"

set selection [ns_db select $db $select_sql]

set host_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "    <li> <a href=\"host-view.tcl?[export_url_vars host_id]\">$hostname</a>"
    incr host_count
}

if { $host_count == 0 } {
    ns_write "    <li> No hosts found.  Would you like to <a href=\"host-add.adp\">add one</a>?\n</ul>"
} else {
    ns_write "</ul>\nOr <a href=\"host-add.adp\">add a new host</a>?\n"
}



# Certificate stuff

ns_write "<br><br><br> <h3>Certificates</h3>
<ul>"

set select_sql "
select hostname, expires, cert_id,
       trunc(months_between(expires, sysdate), 2) as expire_months
  from glassroom_certificates
 order by hostname
"

set selection [ns_db select $db $select_sql]

set cert_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "    <li> <a href=\"cert-view.tcl?[export_url_vars cert_id]\">$hostname</a>"

    if { $expire_months < 0} {
	ns_write "    <font color=red>Certificate has <blink>expired</blink></font>"
    } elseif { $expire_months < $cert_expire_threshold } {
	ns_write "    <font color=red>Certificate will soon expire</font>"
    }
    incr cert_count
}

if { $cert_count == 0 } {
    ns_write "    <li> No certificates found.  Would you like to <a href=\"cert-add.adp\">add one</a>?\n</ul>"
} else {
    ns_write "</ul>\nOr <a href=\"cert-add.adp\">add a new certificate</a>?\n"
}



# Domain stuff

ns_write "<br><br><br> <h3>Domains</h3>
<ul>"

set select_sql "
select domain_name, expires,
       trunc(months_between(expires, sysdate), 2) as expire_months
  from glassroom_domains
 order by domain_name
"

set selection [ns_db select $db $select_sql]

set domain_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "    <li> <a href=\"domain-view.tcl?[export_url_vars domain_name]\">$domain_name</a>"

    if { $expire_months < 0} {
	ns_write "    <font color=red>Domain has <blink>expired</blink></font>"
    } elseif { $expire_months < $domain_expire_threshold } {
	ns_write "    <font color=red>Domain will soon expire</font>"
    }
    incr domain_count
}

if { $domain_count == 0 } {
    ns_write "    <li> No domains found.  Would you like to <a href=\"domain-add.adp\">add one</a>?\n</ul>"
} else {
    ns_write "</ul>\nOr <a href=\"domain-add.adp\">add a new domain</a>?\n"
}





# that's all, folks

ns_db releasehandle $db

ns_write "

[glassroom_footer]
"

