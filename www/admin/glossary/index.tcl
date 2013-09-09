# /www/admin/glossary/index.tcl

ad_page_contract {
    display links to terms alphabetically, seperate sections for approved and suggested terms
  
    @author Jin S Choi (jsc@arsdigita.com)
    @cvs-id: index.tcl,v 3.3.2.4 2000/09/22 01:35:26 kevin Exp
} {} 

set user_id [ad_maybe_redirect_for_registration]

set whole_page "[ad_admin_header "Terms Defined"]
<h2>Terms Defined</h2>
[ad_admin_context_bar Glossary]
<hr>
"

set sql "select term
from glossary
where approved_p = 'f'
order by upper(term)"


set old_first_char ""
set count 0
set pending_items ""

db_foreach glossary_loop $sql {
    set first_char [string toupper [string index $term 0]]
    if { [string compare $first_char $old_first_char] != 0 } {
	if { $count > 0 } {
	    append pending_items "</ul>\n"
	}
	append pending_items "<h3>$first_char</h3>\n<ul>\n"
    }
    
    append pending_items "<li><a href=\"one?[export_url_vars term]\">$term</a>\n"
    append pending_items "\[ <a href=\"term-approve?[export_url_vars term]\">Approve</a> \]\n"

    set old_first_char $first_char
    incr count
}


if { ![empty_string_p $pending_items] } {
    append whole_page "<h3>Pending Definitions</h3>
<ul>
$pending_items
</ul>
</ul>
"
}

append whole_page "

<h3>Approved Definitions</h3>
<blockquote>
"

set sql "select term
from glossary
where approved_p = 't'
order by upper(term)"

set old_first_char ""
set count 0

db_foreach glossary_loop $sql {    
    set first_char [string toupper [string index $term 0]]
    if { [string compare $first_char $old_first_char] != 0 } {
	if { $count > 0 } {
	    append whole_page "</ul>\n"
	}
	append whole_page "<h3>$first_char</h3>\n<ul>\n"
    }
    
    append whole_page "<li><a href=\"one?[export_url_vars term]\">$term</a>\n"

    set old_first_char $first_char
    incr count
}

db_release_unused_handles

append whole_page "</ul>

<p>
<a href=\"term-new\">Add a Term</a>

</blockquote>

[ad_admin_footer]
"
doc_return  200 text/html $whole_page

