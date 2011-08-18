# $Id: form.tcl,v 3.0 2000/02/06 02:43:27 ron Exp $
#
# /acs-examples/spellcheck/form.tcl
#
# by philg@mit.edu, November 8, 1999
#
# beginning of spellcheck demo
#

ns_return 200 text/html "[ad_header "Talk to the psychiatrist"]

<h2>Talk to the psychiatrist</h2>

[ad_context_bar_ws_or_index "Talk"]

<hr>

<form method=post action=\"/tools/spell.tcl\">
<!-- here is the magic stuff we need for the spellcheck tool -->
<input type=hidden name=\"var_to_spellcheck\" value=\"dream\">
<input type=hidden name=\"target_url\" value=\"/acs-examples/spellcheck/form-2.tcl\">

Your first name:
<input type=text name=first_name size=15>

<p>

Your occupation: 
<input type=text name=occupation size=15>

<p>

Your dream last night:

<p>

<blockquote>
<textarea name=dream rows=10 cols=60 wrap=soft>

</textarea>
</blockquote>

<center>
<input type=submit value=\"Submit your thoughts\">
<center>
</form>

[ad_footer]
"
