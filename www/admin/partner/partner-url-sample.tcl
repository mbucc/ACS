# /www/admin/partner/partner-url-sample.tcl,

ad_page_contract {
    Samples template for a url

    @param url_id URL we are looking at

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-url-sample.tcl,v 3.1.2.4 2000/09/22 01:35:46 kevin Exp
} {
    url_id:naturalnum,notnull
}


db_1row partner_url \
	"select u.url_stub, p.partner_cookie
           from ad_partner p, ad_partner_url u
          where u.url_id=:url_id
            and p.partner_id=u.partner_id"

if { ![regexp {/$} $url_stub] } {
    append url_stub "/"
}

set whole_page "
<base href=\"[ad_parameter SystemURL]$url_stub\">
[ad_partner_header $partner_cookie]
<h1>This is the contents of your page</h1>
[ad_partner_footer $partner_cookie]
"



doc_return  200 text/html $whole_page