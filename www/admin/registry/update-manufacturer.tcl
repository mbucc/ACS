ad_page_contract {
    @cvs-id update-manufacturer.tcl,v 3.1.6.3 2000/09/09 20:48:44 kevin Exp
} {
    stolen_id:integer,notnull
    manufacturer:notnull
}

db_dml registry_update { update stolen_registry 
                         set manufacturer = :manufacturer
                         where stolen_id = :stolen_id }

ad_returnredirect "one-case?stolen_id=$stolen_id"
