# $Id: lump-into-about-2.tcl,v 3.0 2000/02/06 03:26:17 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables
   
# lump_about, lump_ids

set lump_ids [util_GetCheckboxValues [ns_conn form] lump_ids]

if { $lump_ids == 0 } {
    ns_return 200 text/plain "oops!  You didn't pick any posting"
}

set db [neighbor_db_gethandle]

ReturnHeaders

ns_write "[neighbor_header "lumping"]

<h2>Lumping</h2>

<hr>

Going to lump 

<blockquote>

[join $lump_ids ","]

</blockquote>

into \"$lump_about\" ..."

ns_db dml $db "update neighbor_to_neighbor 
set about = '$QQlump_about'
where neighbor_to_neighbor_id in ([join $lump_ids ","])"

ns_write "... done.

[neighbor_footer]
"

