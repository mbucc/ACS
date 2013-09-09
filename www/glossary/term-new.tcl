# /www/glossary/term-new.tcl

ad_page_contract {
    form new term postings
    
    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id term-new.tcl,v 3.4.2.5 2000/11/18 07:01:15 walter Exp
} {}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]

if { [ad_parameter ApprovalPolicy glossary] == "open"} {
    set verb "Add"
} elseif { [ad_parameter ApprovalPolicy glossary] == "wait"} {
    set verb "Suggest"
} else {
    if {![ad_administrator_p]} {
	ad_returnredirect "index"
	return
    } else {
	set verb "Add"
    }
}

set whole_page "[ad_header "$verb a Term"]
<h2>$verb a Term</h2>
[ad_context_bar_ws_or_index [list "index" Glossary] "$verb Term"]
<hr>
<form method=post action=\"term-new-2\">
<table>
<tr><th>Term <td><input type=text size=40 name=term>
<tr><th>Definition <td><textarea cols=60 rows=6 wrap=soft name=definition></textarea>
</tr>
</table>
<br>
<center>
<input type=\"submit\" value=\"Submit\">
</center>
</form>
[ad_footer]
"

doc_return  200 text/html $whole_page
