# /www/glossary/term-edit-2.tcl
ad_page_contract {
    executes update to glossary for term
    
    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id  term-edit-2.tcl,v 3.3.2.6 2000/11/18 07:01:11 walter Exp
    @param term The term to edit
    @param definition the new definition
} {
    term:notnull,trim
    definition:notnull,trim,html
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]



page_validation {
    if { ![string equal -nocase "open" [ad_parameter ApprovalPolicy glossary]] } {
	if {![ad_administrator_p]} {
	    error "<li>Only the administrator may edit terms."
	}
    }
} {
    set sql "select author
    from glossary
    where term = :term"

    set author [db_string getauthor $sql]

    # check to see if ther user was the original author
    if {$user_id != $author } {
	if {![ad_administrator_p]} {
	    error "<li>You can not edit this term because you did not author it.\n"
	}
    }
} 

set sql "update glossary set definition = :definition where term = :term"

db_dml update_term $sql

db_release_unused_handles

ad_returnredirect "one?[export_url_vars term]"