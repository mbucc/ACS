# admin/neighbor/toggle-approved-p.tcl
ad_page_contract {
    Toggles the approval of a neighbor_to_neighbor row

    @param neighbor_to_neighbor_id:integer
    @creation-date 2000-07-17
    @author Unknown (Fixed by tnight@arsdigita.com)
    @cvs-di toggle-approved-p.tcl,v 3.3.2.4 2000/07/25 08:39:45 kevin Exp
} {
    neighbor_to_neighbor_id:integer
}

# toggle-approved-p.tcl,v 3.3.2.4 2000/07/25 08:39:45 kevin Exp



db_dml unused "
       update neighbor_to_neighbor 
          set approved_p = logical_negation(approved_p) 
        where neighbor_to_neighbor_id = :neighbor_to_neighbor_id
"
db_release_unused_handles

ad_returnredirect "view-one?[export_url_vars neighbor_to_neighbor_id]"

