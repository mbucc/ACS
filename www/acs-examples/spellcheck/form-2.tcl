# $Id: form-2.tcl,v 3.0 2000/02/06 02:43:27 ron Exp $
#
# /acs-examples/spellcheck/form-2.tcl
#
# by philg@mit.edu, November 8, 1999
#
# end of spellcheck demo
#

set_the_usual_form_variables

# first_name, occupation, dream

ns_return 200 text/html "[ad_header "The psychiatrist talks"]

<h2>The psychiatrist talks</h2>

[ad_context_bar_ws_or_index "Listen"]

<hr>

Very interesting, $first_name.

<p>

You sound conflicted about sticking with the occupation of $occupation.

<p>

You are to be commended for your dreaming orthography in 

<blockquote>
$dream

</blockquote>

[ad_footer]
"
