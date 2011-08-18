# $Id: term-new-2.tcl,v 3.0.4.1 2000/04/28 15:10:55 carsten Exp $
# display a confirmation page for new news postings

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}

set_the_usual_form_variables
# term, definition

set exception_count 0
set exception_text ""

if { [ad_parameter ApprovalPolicy glossary] == "closed" } {
    incr exception_count
    append exception_text "<li>Only the administrator may add a term."
} else {
    if { ![info exists term] || $QQterm == ""} {
	incr exception_count
	append exception_text "<li>Please enter a term to define."
    }
    if { ![info exists definition] || $QQdefinition == "" } {
	incr exception_count
	append exception_text "<li>Please enter a definition for the term."
    }
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}


ReturnHeaders

ns_write "[ad_header "Confirm"]

<h2>Confirm</h2>

[ad_context_bar_ws_or_index [list "index.tcl" Glossary]  [list "term-new.tcl" "Add Term"] Confirm]
<hr>

<h3>What viewers of your definition will see</h3>

<b>$term</b>:
<blockquote>$definition</blockquote>
<p>

<form method=post action=\"term-new-3.tcl\">
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>


[ad_footer]"


