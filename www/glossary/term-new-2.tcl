# /www/glossary/term-new-2.tcl

ad_page_contract {
    display a confirmation page for new news postings
    
    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id: term-new-2.tcl,v 3.4.2.7 2000/11/18 07:01:13 walter Exp
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

set user_id [ad_maybe_redirect_for_registration]


page_validation {
    if { [ad_parameter ApprovalPolicy glossary] == "closed" } {
	if {![ad_administrator_p]} {
	    error "<li>Only the administrator may add a term."
	}
    } 
} 
 

set whole_page "[ad_header "Confirm"]

<h2>Confirm</h2>

[ad_context_bar_ws_or_index [list "index" Glossary]  [list "term-new" "Add Term"] Confirm]
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

