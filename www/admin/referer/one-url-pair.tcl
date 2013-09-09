# /www/admin/referer/one-url-pair.tcl
#

ad_page_contract {
   
    we end up quoting the HTML because sometimes this stuff gets into the 
    database with weird bogosities from broken pages and tolerant browsers

    @cvs-id Id: one-url-pair.tcl,v 3.3.2.2 2000/07/13 06:27:03 paul Exp $
    @param local_url
    @param foreign_url
} {
    local_url:notnull
    foreign_url:notnull
}


set page_content "[ad_admin_header "[ns_quotehtml $foreign_url] -&gt; [ns_quotehtml $local_url]</title>"]

<h3>

<a href=\"$foreign_url\">
[ns_quotehtml $foreign_url]
</a>

 -&gt;

<a href=\"$local_url\">
[ns_quotehtml $local_url]
</a>
</h3>

[ad_admin_context_bar [list "" "Referrals"] "One URL Pair"]

<hr>

<ul>

"


set sql "select entry_date, click_count
from referer_log
where local_url = :local_url
and foreign_url = :foreign_url
order by entry_date desc"

db_foreach referer_local_foreign_pair $sql {
    append page_content "<li>$entry_date : $click_count\n"
}

append page_content "
</ul>

<h4>Still not satisfied?</h4>

The ArsDigita Community System software can build you a report of

<ul>

<li><a href=\"all-from-foreign?foreign_url=[ns_urlencode $foreign_url]\">
all referrals to [ad_system_name] from [ns_quotehtml $foreign_url]</a>
(lumping together all the referring pages)
<li>
<a href=\"all-to-local?local_url=[ns_urlencode $local_url]\">
all referrals to [ns_quotehtml $local_url]</a>
(lumping together all the foreign URLs)
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content