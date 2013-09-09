ad_page_contract {
    End of spellcheck demo.
    
    @author Philip Greenspun [philg@mit.edu]
    @creation-date November 8, 1999
    @cvs-id form-2.tcl,v 3.0.12.4 2000/09/22 01:34:10 kevin Exp
} {
    first_name
    occupation
    dream
} 

doc_return  200 text/html "[ad_header "The psychiatrist talks"]

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
