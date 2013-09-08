# /www/glossary/one.tcl

ad_page_contract {
    query the database for information about one term (definition)
    get the user id in case the person is logged in and we want to offer
    an edit option
    
    @author unknown later modified by walter@arsdigita.com, 2000-07-02
    @cvs-id one.tcl,v 3.2.2.5 2000/09/22 01:38:05 kevin Exp
    @param term The term to display
} {term}

set user_id [ad_get_user_id]


set whole_page "[ad_header $term]

<h2>$term</h2>

[ad_context_bar_ws_or_index [list "index" Glossary] "One Term"]

<hr>

<i>$term</i>:
"

set definition [db_string getterm "select definition from glossary where term = :term" -default ""]

if { [empty_string_p $definition]} {
    set definition "Not defined in glossary."
}

db_release_unused_handles

append whole_page "
<blockquote>$definition</blockquote>
[ad_footer]
"
doc_return  200 text/html $whole_page


