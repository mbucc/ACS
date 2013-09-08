# /www/admin/glossary/term-new-2.tcl   

ad_page_contract {
    display a confirmation page for new news postings
    
    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id: term-new-2.tcl,v 3.3.2.10 2000/11/18 06:13:19 walter Exp
    @param term the term to define
    @param definition the definition
} {
    term:notnull,trim
    definition:notnull,html,trim
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set whole_page "[ad_header "Confirm"]

<h2>Confirm</h2>

[ad_admin_context_bar [list "index" "Glossary"] [list "term-new" "Add Term"] Confirm]

<hr>

<h3>What viewers of your definition will see</h3>

<b>$term</b>:
<blockquote>$definition</blockquote>
<p>

<form method=post action=\"term-new-3\">
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>


[ad_footer]"

doc_return  200 text/html $whole_page

