ad_library {

    philg@mit.edu had to write this on March 7, 1999 because Jin was too lazy
    this allows authors to reference /gl/Internet for the definition of the
    term Internet.
    @author Philip Greenspun [philg@mit.edu]
    @creation-date March 7, 1999
    @cvs-id ad-glossary.tcl,v 3.3.2.7 2000/11/18 05:43:53 walter Exp
}


ns_share -init {set ad_glossary_filters_installed 0} ad_glossary_filters_installed

if {!$ad_glossary_filters_installed} {
    ad_register_filter preauth HEAD /admin/glossary/* ad_restrict_to_administrator
    ad_register_filter preauth GET  /admin/glossary/* ad_restrict_to_administrator
    ad_register_filter preauth POST /admin/glossary/* ad_restrict_to_administrator
    ad_register_proc GET /gl glossary_direct_lookup
}



# modified by walter@arsdigita.com, 200-07-02
# to use new db api and comply more closely with acs conventions
proc glossary_direct_lookup {ignore} {
    if { ![regexp {/gl/(.+)$} [ns_conn url] match term] } {
	ad_return_error "Couldn't find the term" "References in the glossary system are supposed to look like
\"/gl/**term**\"."
    } else {
	# found the term in the URL, let's just run the code from /glossary/one.tcl
	regsub -all {\+} $term " " term
	# set QQterm [DoubleApos $term]  #na- we use bind vars now
  	set whole_page "
	[ad_header $term]

	<h2>$term</h2>

	[ad_context_bar_ws_or_index [list "index" Glossary] "One Term"]

	<hr>

	<i>$term</i>:
	"

	set definition [db_string definition_display {
	    select definition from glossary where term = :term
	} -default ""]

	if { $definition == "" } {
	    # Try again, case insensitively.

	    set caseless_term [string tolower $term]
	    set definition [db_string caseless_definition_display {
		select definition from glossary 
		where lower(term) = :caseless_term
	    } -default ""]
	    if { $definition == "" } {
		set definition "Term not defined."
	    } 
	}

	db_release_unused_handles

	append whole_page "
	<blockquote>$definition</blockquote>
	[ad_footer]
	"
	doc_return  200 text/html $whole_page
    }
}