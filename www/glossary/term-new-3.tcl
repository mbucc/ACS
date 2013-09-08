# /www/glossary/term-new-3.tcl

ad_page_contract {
    carries out insert into glossary for new term
    
    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id term-new-3.tcl,v 3.4.2.6 2000/09/22 01:38:06 kevin Exp
    @param term The term we to define
    @param definition The definition
} {
    term:notnull,trim
    definition:notnull,html,trim
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]

if { [ad_parameter ApprovalPolicy glossary] == "open"} {
    set approved_p "t"
} else {
    set approved_p "f"
}



db_dml add_suggestion "insert into glossary
(term, definition, author, approved_p, creation_date)
  select :term, :definition, :user_id, :approved_p, sysdate 
  from dual
  where not exists (select 1 from glossary where term = :term)"

set insert_success_p [db_string add_suggestion_check "select count(*) from glossary 
   where term = :term and definition = :definition and author = :user_id"]

db_release_unused_handles

if { $insert_success_p } {
    if { [ad_parameter ApprovalPolicy glossary] == "open"} {
	ad_returnredirect "index"
    } else {
	doc_return  200 text/html "[ad_header "Thank you"]

	<h2>Thank You For Your Submission</h2>
	[ad_context_bar_ws_or_index [list "index" Glossary]  [list "term-new" "Add Term"] Submitted]
	<hr>

	Your submission will be reviewed by 
	[ad_parameter SystemOwner glossary [ad_system_owner]].

	[ad_footer]"
    }
} else {
    doc_return  200 text/html "[ad_header "Submission failed"]
  <h2>Submission failed</h2>
    [ad_context_bar_ws_or_index [list "index" Glossary]  [list "term-new" "Add Term"] Submitted]
    <hr>
    <p> We are sorry. Your submission of <i>$term</i> failed. Most likely, somebody defined 
    this term already. Take a look at <a href=\"index\">the list</a> of all defined terms.
    
    [ad_footer]"
}

