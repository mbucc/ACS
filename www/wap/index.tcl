# /www/wap/index.tcl
ad_page_contract {

    Redirects WAP devices to the top-level WAP index and presents
    a little introduction for folks with HTML browsers.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date  29 May 2000
    @cvs-id index.tcl,v 1.3.2.4 2000/09/22 01:39:27 kevin Exp
} {}

switch [util_guess_doctype] {
    wml { 
	# This is a WAP device.
	set index_page [ad_parameter SpecialIndexPage wap]
	if ![empty_string_p $index_page] {
	    wap_returnredirect $index_page
	    return
	} else {
	    wml_return -no_cache "
<wml>
  <head>
    <meta http-equiv=\"Cache-Control\" content=\"max-age=0\"/>
  </head>
  <card>
    <p>Welcome to ACS WAP!</p>
  </card>
</wml>
            "
        }
    }

    default {
	# Device unknown; probably an HTML browser.
	set page_content "
[ad_header "WAP Home"]
<h2>WAP Home</h2>
[ad_context_bar_ws_or_index "WAP Home"]
<hr>
This is the homepage for WAP devices on [ad_parameter SystemName], ACS version: [ad_acs_version].  So far as we can tell, you are viewing this page with an HTML browser.  Were you to visit this page with a WAP device, you would be able to use the following services:
<ul>
<li>Employee phone directory (part of <a href=\"/intranet\">intranet</a>)
<!-- Add more services here -->
"

    set default_domain [wap_default_email_domain]
    if ![empty_string_p $default_domain] {
	append page_content "
<p>
<li>Login Hint: If your email address ends in @$default_domain, you can omit this part when logging in."
    }

    append page_content "
</ul>

[ad_footer]"
	doc_return  200 text/html $page_content
    }
}

