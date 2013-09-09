# /www/admin/gc/toggle-active-p.tcl
ad_page_contract {
    Activates or deactivates a domain by setting active_p appropriately.
    
    @author xxx
    @creation-date unknown
    @cvs-id toggle-active-p.tcl,v 3.2.6.3 2000/07/21 03:57:20 ron Exp
} {
    domain_id:integer
}


db_dml toggle_domain_active_p "update ad_domains set active_p = logical_negation(active_p) where domain_id = $domain_id"

ad_returnredirect "index.tcl"
