# /banned.tcl


ad_page_contract {
    where users get redirected to if banned in the middle of a logged in session

    @author sarah@arsdigita.com
    @creation-date  2000-05-25
    @cvs-id banned.tcl,v 3.1.2.3 2000/09/22 01:38:04 kevin Exp
} {

}

set signatory [ad_system_owner]

set page_contents "[ad_header "Banned"]

<p>
You have been banned from this website.

<p>

Please contact <a href=\"mailto:$signatory\">$signatory</a> for further information.

[ad_footer]"

doc_return  200 text/html $page_contents
