# $Id: one-url-pair.tcl,v 3.0 2000/02/06 03:14:49 ron Exp $
set_the_usual_form_variables

# local_url, foreign_url

ReturnHeaders

ns_write "[ad_admin_header "$local_url -&gt; $foreign_url</title>"]

<h3>

<a href=\"/$local_url\">
$local_url
</a>

 -&gt;

<a href=\"$foreign_url\">
$foreign_url
</a>
</h3>

[ad_admin_context_bar [list "report.tcl" "Clickthroughs"] "One URL Pair"]


<hr>

<ul>

"
set db [ns_db gethandle]

set selection [ns_db select $db "select entry_date, click_count
from clickthrough_log
where local_url = '$QQlocal_url' 
and foreign_url = '$QQforeign_url'
order by entry_date desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>$entry_date : $click_count\n"
}

ns_write "
</ul>

<h4>Still not satisfied?</h4>

[ad_system_name] adminstration can build you a report of
<ul>

<li><a href=\"all-to-foreign.tcl?foreign_url=[ns_urlencode $foreign_url]\">
all clickthroughs from [ad_system_name] to $foreign_url</a>
(lumping together all the referring pages)
<li>
<a href=\"all-from-local.tcl?local_url=[ns_urlencode $local_url]\">
all clickthroughs from $local_url</a>
(lumping together all the foreign URLs)
</ul>


[ad_admin_footer]
"


