#amdin/neighbor/lump-into-about-2.tcl
ad_page_contract {
    Not sure it gets used, lumps postings does a dml
    @cvs-id: lump-into-about-2.tcl,v 3.0.12.4 2000/09/22 01:35:43 kevin Exp
} {
    lump_about:sql_identifier
    lump_ids
}

set lump_ids [util_GetCheckboxValues [ns_conn form] lump_ids]

if { $lump_ids == 0 } {
    doc_return  200 text/plain "oops!  You didn't pick any posting"
}


append doc_body "[neighbor_header "lumping"]

<h2>Lumping</h2>

<hr>

Going to lump 

<blockquote>

[join $lump_ids ","]

</blockquote>

into \"$lump_about\" ..."

db_dml neighbor_to_neighbor_update "update neighbor_to_neighbor 
set about = :lump_about
where neighbor_to_neighbor_id in ([join $lump_ids ","])"

append doc_body "... done.

[neighbor_footer]
"

doc_return  200 text/html $doc_body