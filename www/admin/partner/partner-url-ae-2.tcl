# $Id: partner-url-ae-2.tcl,v 3.0.4.1 2000/04/28 15:09:13 carsten Exp $
set_the_usual_form_variables
# partner_id, url_stub, url_id

# Check arguments
set err ""
set req_vars [list partner_id url_id url_stub]
foreach var $req_vars {
    if { ![exists_and_not_null $var] } {
	append err "  <LI> Must specify $var\n"
    }
}

if { [info exists url_stub] && ![regexp {^/} $url_stub] } {
    append err "  <LI> URL Stub must start with a leading forward slash\n"
}

set db [ns_db gethandle]

# Check for uniqueness
set exists_p [database_to_tcl_string $db \
	"select decode(count(*),0,0,1) 
           from ad_partner_url 
          where partner_id=$partner_id 
            and url_stub='$QQurl_stub' 
            and url_id != $url_id"]

if { $exists_p } {
    append err "  <li> Specified url \"$url_stub\" has already been registered for this partner\n"
}

if { ![empty_string_p $err] } {
    ad_partner_return_error "Problems with your input" "<UL> $err</UL>"
    return
}

ns_db dml $db "begin transaction"

ns_db dml $db "update ad_partner_url set 
               url_stub='$QQurl_stub'
               where url_id = $url_id"

if {[ns_ora resultrows $db] == 0} {
    ns_db dml $db "insert into ad_partner_url
(partner_id, url_id, url_stub)
values 
($partner_id, $url_id, '$QQurl_stub')"
}

ns_db dml $db "end transaction"

ad_returnredirect "partner-view.tcl?[export_url_vars partner_id]"

