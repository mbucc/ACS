ad_page_contract {
    Contests

    @cvs-id index.tcl,v 3.3.6.4 2000/09/22 01:37:18 kevin Exp
} 

set the_page "[ad_header "All [ad_system_name] Contests"]

<h2>Contests</h2>

at [ad_site_home_link]

<hr>

<ul>
"

set sql "select domain_id, home_url, pretty_name
from contest_domains
where sysdate between start_date and end_date
order by upper(pretty_name)"

set counter 0
db_foreach contest_domains $sql {
    incr counter 
    append the_page "<li><a href=\"entry-form?[export_url_vars domain_id]\">$pretty_name</a>\n"
}

if { $counter == 0 } {
    append the_page "there are no live contests at present"
}

append the_page "</ul>

[ad_footer]
"

doc_return  200 text/html $the_page

