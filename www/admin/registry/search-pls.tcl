# $Id: search-pls.tcl,v 3.0 2000/02/06 03:28:05 ron Exp $
set use_context_p 0

set_the_usual_form_variables

# query_string is the only one

set db [ns_db gethandle]

if $use_context_p {
    regsub -all { +} $query_string "," query_string_for_ctx
    regsub -all {,+} $query_string_for_ctx "," query_string_for_ctx

    set sql "select stolen_id, manufacturer, model, serial_number
from stolen_registry_for_context
where contains (indexedtext, '\$([DoubleApos $query_string_for_ctx])', 10) > 0
and deleted_p <> 't'
and recovered_p <> 't'
order by score(10) desc"

} else {
    # if the user put in commas, replace with spaces
    regsub -all {,+} [string trim $QQquery_string] " " final_query_string
    set sql "select pseudo_contains (indexedtext, '$final_query_string') as the_score, stolen_id, manufacturer, model, serial_number
from stolen_registry_for_context
where pseudo_contains (indexedtext, '$final_query_string') > 0
and deleted_p <> 't'
and recovered_p <> 't'
order by 1 desc"
}

ReturnHeaders

ns_write "[ad_admin_header "Full Text Search Results"]

<h2>Search Results for \"$query_string\"</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "Search Results"]


<hr>

<ul>
"

if [catch { set selection [ns_db select $db $sql] } errmsg] {

    ns_write "Ooops!  Some kind of problem with our database:  
<blockquote>
$errmsg
</blockquote>
<p>

In the meantime, you can always search by manufacturer from the preceding page."

} else {
    # the PLS query actually succeeded (miracles do occur)
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if [empty_string_p $serial_number] {
	    set serial_number "No serial number provided"
	}
        ns_write "<li>$manufacturer $model, serial number <a href=\"one-case.tcl?stolen_id=$stolen_id\">$serial_number</a>"
    }



}

ns_write "

</ul>

[ad_admin_footer]
"
