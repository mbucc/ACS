# domain-add-2.tcl

ad_page_contract {
    Create new domain.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id domain-add-2.tcl,v 1.4.6.4 2000/07/31 18:03:28 tony Exp
} {
    full_name:notnull
    short_name:notnull
}

if [db_0or1row check_if_domain_exists "select short_name as sn 
from wm_domains where short_name = :short_name"] {
    ad_return_complaint 1 "Short name already exists. You either double-clicked or forgot to choose an unique short name" 
    return
} else {
    db_dml add_domain {
	insert into wm_domains (short_name, full_domain_name)
	values (:short_name, :full_name)
    }
}

ad_returnredirect "index.tcl"