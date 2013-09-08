ad_page_contract {
    This is for converting old emails.

    @author xxx
    @date unknown
    @cvs-id convert-old-alerts.tcl,v 3.2.2.4 2000/09/22 01:37:51 kevin Exp
} {

}

set html "<html><head><title>Convert</title></head> 
<body>
<ul>"

set update_html ""

db_foreach convert_old_alerts_query "
select
  oid,
  *
from classified_email_alerts" {
    append html "<li>for $email (oid: $oid)
    <ul>
    <li>Old query:  $query"
    regsub {and[^a-zA-Z]+primary_category = 'photographic'} $query "" without_primary
    append html "<li>without primary:  $without_primary"
    regsub {subcategory_1} $without_primary "primary_category" final_query
    append html "<li>final:  $final_query"
    append html "</ul>"

    db_dml convert_old_email_dml "update classified_email_alerts 
    set query = :final_query
    where oid=:oid" -bind [ad_tcl_vars_to_ns_set final_query oid]

    append update_html "<li>Completed: update classified_email_alerts 
    set query = $final_query
    where oid=$oid\n"
}


append html "</ul>

<p>
<h3>Now for the updates</h3>

<ul>
$update_html
</ul>

</body>
</html>"



doc_return  200 text/html $html
