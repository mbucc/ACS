# /www/admin/neighbor/lumping/delete.tcl
ad_page_contract {
    Deletes a neighbor-to-neighbor posting.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id delete.tcl,v 3.0.12.4 2000/09/22 01:35:43 kevin Exp
    @param neighbor_to_neighbor_id the posting to delete
} {
    neighbor_to_neighbor_id:integer,notnull
}
db_dml delete_post "
  delete from neighbor_to_neighbor 
   where neighbor_to_neighbor_id = :neighbor_to_neighbor_id"

doc_return  200 text/plain "Deleted posting $neighbor_to_neighbor_id"
