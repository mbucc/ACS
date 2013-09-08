# www/admin/registry/delete.tcl

ad_page_contract {
    @cvs-id delete.tcl,v 3.1.6.2 2000/07/25 08:36:32 kevin Exp
} {
    stolen_id:integer,notnull
    manufacturer:notnull
}

db_dml registry_delete "delete from stolen_registry where stolen_id = :stolen_id"

ad_returnredirect "search-one-manufacturer.tcl?manufacturer=[ns_urlencode $manufacturer]"
