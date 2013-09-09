# /www/admin/partner/partner-url-ae-2.tcl

ad_page_contract {
    Writes url stub to database

    @param partner_id 
    @param url_id 
    @param url_stub 
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-url-ae-2.tcl,v 3.2.2.4 2000/07/25 09:40:59 kevin Exp
} {
    partner_id:naturalnum,notnull
    url_id:naturalnum,notnull,verify
    url_stub:trim
    { return_url "" }
}


set err ""
if { ![regexp {^/} $url_stub] } {
    append err "  <LI> URL Stub must start with a leading forward slash\n"
}

if { [string length $url_stub] > 50 } {
    append err "  <LI> URL Stub cannot exceed 50 characters\n"
}

# Check for uniqueness
set exists_p [db_string partner_url_stub_exists \
	"select decode(count(*),0,0,1) 
           from ad_partner_url 
          where partner_id=:partner_id 
            and url_stub=:url_stub
            and url_id <> :url_id"]

if { $exists_p } {
    append err "  <li> Specified url \"$url_stub\" has already been registered for this partner\n"
}

if { ![empty_string_p $err] } {
    ad_partner_return_error "Problems with your input" "<UL> $err</UL>"
    return
}

db_dml partner_url_update \
	"update ad_partner_url 
            set url_stub=:url_stub
          where url_id = :url_id"

if { [db_resultrows] == 0 } {
    db_dml partner_url_insert "insert into ad_partner_url
(partner_id, url_id, url_stub)
values 
(:partner_id, :url_id, :url_stub)"
}

if { [empty_string_p $return_url] } {
    set return_url "partner-view?[export_url_vars partner_id]"
}

db_release_unused_handles

ad_returnredirect $return_url
