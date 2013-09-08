ad_page_contract {
    Prints out information and source code on a defined site-wide style.

    @param style_name

    @author ?
    @creation-date ?
    @cvs-id style-one.tcl,v 3.2.2.4 2000/09/22 01:37:23 kevin Exp
} {
    style_name:notnull
}


ns_share ad_styletag
ns_share ad_styletag_source_file


doc_return  200 text/html "[ad_admin_header "One Style"]
<h2>One Style</h2>

defined in $ad_styletag_source_file($style_name), part of the
<a href=\"styles\">style module</a> of the ArsDigita Community System

<hr>

This page shows the available information on one style defined using <code>ad_register_styletag</code>.

<h3>$style_name</h3>

<blockquote>

$ad_styletag($style_name)

</blockquote>

Source code:
<pre>
[philg_quote_double_quotes [info body ad_style_$style_name]]
</pre>

[ad_admin_footer]
"

