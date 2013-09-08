# /www/admin/glossary/one.tcl

ad_page_contract {
    
    query the database for information about one term (definition)
    get the user id in case the person is logged in and we want to offer
    an edit option
    
    @author Walter McGinnis (walter@arsdigita.com)
    @cvs-id one.tcl,v 3.3.2.7 2000/09/22 01:35:26 kevin Exp
    @param term the term to view
} {term} 

set user_id [ad_maybe_redirect_for_registration]

set whole_page "[ad_admin_header $term]

<h2>$term</h2>

[ad_admin_context_bar [list "index" Glossary] "One Term"]

<hr>

<i>$term</i>:
"

set selection [db_0or1row admin_glossary_get_term "select definition, approved_p from glossary where term = :term"]

if {$selection == 0} {
    ad_return_complaint "Term not found" "$term could not be found in the glossary"
    db_release_unused_handles
    return
}

if { [empty_string_p $definition]} {
    set definition ""
    set approved_p 't'
}


append whole_page "
<blockquote>$definition</blockquote>
<ul>
<li><a href=\"term-edit?[export_url_vars term]\">Edit this Term</a>
<p>
<li><a href=\"term-delete?[export_url_vars term]\">Delete this Term (immediate)</a>
"

if { $approved_p == "f" } {
    append whole_page "<li><a href=\"term-approve?[export_url_vars term]\">Approve this Term</a>\n"
}

append whole_page "
</ul>

[ad_admin_footer]
"

doc_return  200 text/html $whole_page

