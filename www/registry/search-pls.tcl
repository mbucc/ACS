# www/registry/search-pls.tcl

ad_page_contract {
    @cvs-id search-pls.tcl,v 3.2.2.4 2000/09/22 01:39:16 kevin Exp
} {
    query_string
}

set use_context_p 0

if $use_context_p {
    regsub -all { +} $query_string "," query_string_for_ctx
    regsub -all {,+} $query_string_for_ctx "," query_string_for_ctx

    set sql "select stolen_id, manufacturer, model, serial_number
    from stolen_registry_for_context
    where contains (indexedtext, :query_string_for_ctx, 10) > 0
    and deleted_p <> 't'
    and recovered_p <> 't'
    order by score(10) desc"

    set bind_vars [ad_tcl_vars_to_ns_set query_string_for_ctx]

} else {
    # if the user put in commas, replace with spaces
    regsub -all {,+} [string trim [DoubleApos $query_string]] " " final_query_string

    set sql "select pseudo_contains (indexedtext, :final_query_string) as the_score, stolen_id, 
                    manufacturer, model, serial_number
    from stolen_registry_for_context
    where pseudo_contains (indexedtext, :final_query_string) > 0
    and deleted_p <> 't'
    and recovered_p <> 't'
    order by 1 desc"

    set bind_vars [ad_tcl_vars_to_ns_set final_query_string]
}

set html "[ad_header "Full Text Search Results"]

<h2>Search Results</h2>

for \"$query_string\" into the <a href=index>Stolen Equipment Registry</a>

<hr>
<ul>
"

#  if [catch { set selection [ns_db select $db $sql] } errmsg] {
#      append html "Ooops!  Some kind of problem with our database:  
#      <blockquote>
#      $errmsg
#      </blockquote>
#      <p>
#      In the meantime, you can always search by manufacturer from the preceding page."
#  }

db_foreach manufacturer_list $sql -bind $bind_vars {
    if [empty_string_p $serial_number] {
	set serial_number "No serial number provided"
    }
    append html "<li>$manufacturer $model, serial number <a href=\"one-case?stolen_id=$stolen_id\">$serial_number</a>"
}

append html "
</ul>
[ad_footer]
"


doc_return  200 text/html $html
