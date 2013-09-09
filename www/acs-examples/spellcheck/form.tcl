ad_page_contract {
    
    Beginning of spellcheck demo.

    @author Philip Greenspun [philg@mit.edu]
    @creation-date November 8, 1999
    @cvs-id form.tcl,v 3.1.6.3 2000/09/22 01:34:11 kevin Exp
} { 
}

doc_return  200 text/html "[ad_header "Talk to the psychiatrist"]

<h2>Talk to the psychiatrist</h2>

[ad_context_bar_ws_or_index "Talk"]

<hr>

<form method=post action=\"/tools/spell\">
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
