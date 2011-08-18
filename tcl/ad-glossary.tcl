# $Id: ad-glossary.tcl,v 3.0 2000/02/06 03:12:25 ron Exp $
# ad-glossary.tcl
# philg@mit.edu had to write this on March 7, 1999 because Jin was too lazy

# this allows authors to reference /gl/Internet for the definition of the
# term Internet

ns_register_proc GET /gl glossary_direct_lookup

proc glossary_direct_lookup {ignore} {
    if { ![regexp {/gl/(.+)$} [ns_conn url] match term] } {
	ad_return_error "Couldn't find the term" "References in the glossary system are supposed to look like
\"/gl/**term**\"."
    } else {
	# found the term in the URL, let's just run the code from /glossary/one.tcl
	regsub -all {\+} $term " " term
	set QQterm [DoubleApos $term]
	ReturnHeaders
	ns_write "[ad_header $term]

	<h2>$term</h2>

	[ad_context_bar_ws_or_index [list "index.tcl" Glossary] "One Term"]

	<hr>

	<i>$term</i>:
	"

	set db [ns_db gethandle]

	set definition [database_to_tcl_string_or_null $db "select definition from glossary where term = '$QQterm'"]

	if { $definition == "" } {
	    # Try again, case insensitively.

	    set definition [database_to_tcl_string_or_null $db "select definition from glossary where lower(term) = '[string tolower $QQterm]'"]
	    if { $definition == "" } {
		set definition "Term not defined."
	    } 
	}

	ns_db releasehandle $db

	ns_write "
	<blockquote>$definition</blockquote>
	[ad_footer]
	"
    }
}
