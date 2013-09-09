# /www/admin/gc/domain-edit-2.tcl
ad_page_contract {
    Lets the site administrator edit a domain.

    @param domain_id which domain
    @param full_noun name for the domain
    @param domain short key
    @param insert_form_fragments form fragment for ad parameters
    @param default_expiration_days
    @param wtb_common_p
    @param auction_p
    @param geocentric_p
    @param submit

    @author philg@mit.edu
    @cvs_id domain-edit-2.tcl,v 3.4.2.3 2000/08/22 23:28:25 kevin Exp
} {
    domain_id:integer
    full_noun:notnull
    domain:notnull
    insert_form_fragments:allhtml
    default_expiration_days:integer
    wtb_common_p
    auction_p
    geocentric_p
    submit
} -validate {
    form_fragment_max_length -requires {insert_form_fragments} {
	if { [string length $insert_form_fragments] > 4000 } {
	    ad_complain "<li>Please limit your form fragment for ad parameters to 4000 characters."
	}
    }
}	

ns_set delkey [ns_conn form] submit

set sql_statement_and_bind_vars [util_prepare_update ad_domains domain_id $domain_id [ns_conn form]]
set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml domain_update $sql_statement -bind $bind_vars} errmsg] {
	    ad_return_error "Failure to update domain information" "The database rejected the attempt:
	    <blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

ad_returnredirect "domain-top.tcl?[export_url_vars domain_id]"

