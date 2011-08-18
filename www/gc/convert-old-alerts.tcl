# $Id: convert-old-alerts.tcl,v 3.1 2000/03/10 23:58:21 curtisg Exp $
set db [gc_db_gethandle]

append html "<html><head><title>Convert</title></head> 
<body>
<ul>"

set selection [ns_db select $db "select oid,* from classified_email_alerts"]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append html "<li>for $email (oid: $oid)
<ul>
<li>Old query:  $query"
    regsub {and[^a-zA-Z]+primary_category = 'photographic'} $query "" without_primary
    append html "<li>without primary:  $without_primary"
    regsub {subcategory_1} $without_primary "primary_category" final_query
    append html "<li>final:  $final_query"
    append html "</ul>"
    lappend updates "update classified_email_alerts 
set query = '[DoubleApos $final_query]'
where oid='$oid'"

}

append html "</ul>

<p>
<h3>Now for the updates</h3>

<ul>

"

foreach update $updates {
    ns_db dml $db $update
    append html "<li>Completed $update\n"
}

append html "</ul>


</body>
</html>"

ns_return 200 text/html $html
