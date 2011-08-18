# $Id: domain-edit-2.tcl,v 3.1.2.1 2000/04/28 15:10:35 carsten Exp $
set_the_usual_form_variables

# domain_id, domain, insert_form_fragments, default_expiration_days,
# wtb_common_p, auction_p, geocentric_p
# submit

# user error checking

set exception_text ""
set exception_count 0

if { ![info exists full_noun] || [empty_string_p $full_noun] } {
    incr exception_count
    append exception_text "<li>Please enter a name for this domain."
}

if { ![info exists domain] || [empty_string_p $domain] } {
    incr exception_count
    append exception_text "<li>Please enter a short key."
}


if { [info exists insert_for_fragments] && [string length $insert_form_fragments] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit you form fragment for ad parameters to 4000 characters."
}

if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}

set db [ns_db gethandle]

ns_set delkey [ns_conn form] submit


set sql_statement  [util_prepare_update $db ad_domains domain_id $domain_id [ns_conn form]]


if [catch { ns_db dml $db $sql_statement } errmsg] {
	    ad_return_error "Failure to update domain information" "The database rejected the attempt:
	    <blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

ad_returnredirect "domain-top.tcl?[export_url_vars domain]"
