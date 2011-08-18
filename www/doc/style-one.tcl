# $Id: style-one.tcl,v 3.0 2000/02/06 03:37:05 ron Exp $
# style-one.tcl
#
# documented at least by philg@mit.edu on July 2, 1999
# written by jsc@arsdigita.com, Jan 25 2000

# prints out information and source code on a defined site-wide style

ns_share ad_styletag
ns_share ad_styletag_source_file

set_form_variables
# style_name

ns_return 200 text/html "[ad_admin_header "One Style"]
<h2>One Style</h2>

defined in $ad_styletag_source_file($style_name), part of the
<a href=\"styles.tcl\">style module</a> of the ArsDigita Community System

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


