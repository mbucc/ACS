ad_page_contract {
    Displays oracle session parameter settings.

    @author Richard Li (richardl@arsdigita.com)
    @author Dave Abercrombie (abe@arsdigita.com)
    @creation-date 14 April 2000
    @cvs-id $Id:
} { 
}

set page_name "Oracle Initialization Parameters"

set page_content "
[ad_admin_header $page_name]
<h2>$page_name</h2>
[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Initialization Parameters" ]
<hr>
<p>These initialization parameter values come from 
the <a href=\"http://docs.oracle.com/cd/E11882_01/server.112/e40402/dynviews_2087.htm#sthref3485\">v\$parameter</a> dynamic 
performance view. Some parameters can be changed with 
the <a href=\"http://docs.oracle.com/cd/E11882_01/server.112/e41084/statements_2014.htm#sthref3285\">ALTER SYSTEM</a> 
or <a href=\"http://docs.oracle.com/cd/E11882_01/server.112/e41084/statements_2013.htm#sthref3228\">ALTER SESSION</a> commands. Note that if you want to change these settings for your specific service (as opposed to changing it system-wide), the ALTER SESSION command takes effect for only the duration of the db handle i.e., you have to execute ALTER SESSION commands each time you grab the db handle.
Others can only be changed by editing
the <a href=\"http://docs.oracle.com/cd/E11882_01/server.112/e25494/create.htm#ADMIN11099\">initialization file</a>
and restarting Oracle. You can also get these same parameters by executing the SHOW PARAMETERS command from inside SQL*Plus.
</p>
<table border=1>
<tr><th>Name</th><th>Value</th><th>Alter Session?</th><th>Alter System?</th></tr>
"

set sql "
-- /admin/cassandracle/oracle-settings
select 
     v.name, 
     nvl(v.value,'&nbsp;') as value,
     lower(v.isses_modifiable) as isses_modifiable,
     lower(v.issys_modifiable) as issys_modifiable
from 
     v\$parameter v 
order by 
     name"

db_foreach mon_oracle_settings $sql {
    append page_content "<tr><td>$name</td><td>$value</td><td>$isses_modifiable</td><td>$issys_modifiable</td></tr>\n"
}

append page_content "</table>
[ad_admin_footer]"


doc_return  200 text/html $page_content
