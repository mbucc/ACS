# $Id: one-url-pair.tcl,v 3.0 2000/02/06 03:27:52 ron Exp $
set_the_usual_form_variables

# local_url, foreign_url

# we end up quoting the HTML because sometimes this stuff gets into the 
# database with weird bogosities from broken pages and tolerant browsers

ReturnHeaders

ns_write "[ad_admin_header "[ns_quotehtml $foreign_url] -&gt; [ns_quotehtml $local_url]</title>"]

<h3>

<a href=\"$foreign_url\">
[ns_quotehtml $foreign_url]
</a>

 -&gt;

<a href=\"$local_url\">
[ns_quotehtml $local_url]
</a>
</h3>

[ad_admin_context_bar [list "index.tcl" "Referrals"] "One URL Pair"]

<hr>

<ul>

"
set db [ns_db gethandle]

set selection [ns_db select $db "select entry_date, click_count
from referer_log
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

The ArsDigita Community System software can build you a report of

<ul>

<li><a href=\"all-from-foreign.tcl?foreign_url=[ns_urlencode $foreign_url]\">
all referrals to [ad_system_name] from [ns_quotehtml $foreign_url]</a>
(lumping together all the referring pages)
<li>
<a href=\"all-to-local.tcl?local_url=[ns_urlencode $local_url]\">
all referrals to [ns_quotehtml $local_url]</a>
(lumping together all the foreign URLs)
</ul>


[ad_admin_footer]
"


