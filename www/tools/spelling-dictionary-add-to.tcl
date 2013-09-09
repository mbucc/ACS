# spelling-dictionary-add-to.tcl

ad_page_contract {
    @author Eve Andersson
    @creation-date
    @cvs-id spelling-dictionary-add-to.tcl,v 3.0.12.3 2000/09/22 01:39:26 kevin Exp
} {
    errword
}


if [catch { db_dml word_insert {
    insert into ispell_words (ispell_word) values (:errword)
}   } ] {
    ad_return_error "Unable to add word" "We were unable to add $errword to the dictionary.  
    It is probably because somebody else tried to add the same word at the same time to the dictionary
    (words in the dictionary must be unique)."
    return
}

# Now that Oracle has handled the transaction control of adding words to the dictionary, bash the
# ispell-words file.  Jin has promised me (eveander) that ispell-words won't become corrupted because,
# since one chunk is only to be added to the file at a time, it is impossible for the chunks to
# become interspersed. 

set ispell_file [open "[ns_info pageroot]/tools/ispell-words" a]

# ispell-words will be of the form: one word per line, with a newline at the end (since -nonewline is not specified)
puts $ispell_file "$errword"

append doc_body "[ad_header "$errword added"]
<h2>$errword has been added to the spelling dictionary</h2>
<hr>
Please push \"Back\" to continue with the spell checker.
[ad_footer]
"

db_release_unused_handles
doc_return 200 text/html $doc_body
