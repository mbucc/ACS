# $Id: partner-url-sample.tcl,v 3.0 2000/02/06 03:26:49 ron Exp $
set_the_usual_form_variables
# url_id

set db [ns_db gethandle]

set selection [ns_db 1row $db \
	"select u.url_stub, p.partner_cookie
           from ad_partner p, ad_partner_url u
          where u.url_id=$url_id
            and p.partner_id=u.partner_id"]
set_variables_after_query
ns_db releasehandle $db

if { ![regexp {/$} $url_stub] } {
    append url_stub "/"
}

ReturnHeaders
ns_write "
<base href=\"[ad_parameter SystemURL]$url_stub\">
[ad_partner_header $partner_cookie]
<h1>This is the contents of your page</h1>
[ad_partner_footer $partner_cookie]
"
