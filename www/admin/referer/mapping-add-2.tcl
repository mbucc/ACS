# $Id: mapping-add-2.tcl,v 3.0.4.1 2000/04/28 15:09:19 carsten Exp $
set_the_usual_form_variables

# everything for referer_log_glob_patterns

set exception_count 0
set exception_text ""

if { ![info exists glob_pattern] || [empty_string_p $glob_pattern] } {
    incr exception_count
    append exception_text "<li>Please enter a pattern to use to lump URL's together."
}
if { ![info exists canonical_foreign_url] || [empty_string_p $canonical_foreign_url] } {
    incr exception_count
    append exception_text "<li>Please enter a URL to group the matches under."
}


if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]

ns_set delkey $form submit

set insert_statement [util_prepare_insert $db referer_log_glob_patterns glob_pattern $glob_pattern [ns_conn form]]

if [catch { ns_db dml $db $insert_statement } errmsg] {
    set n_already [database_to_tcl_string $db "select count(*) from referer_log_glob_patterns where glob_pattern = '$QQglob_pattern'"]
    if { $n_already > 0 } {
	ad_return_error "There is already a mapping for $glob_pattern" "There is already a mapping for the pattern \"$glob_pattern\".
If you didn't hit submit twice by mistake, then perhaps
what you want to do is <a href=\"mapping-change.tcl?[export_url_vars glob_pattern]."
    } else  {
	ad_return_error "Failured to add mapping" "The database rejected the insert:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    }
    return
} 

ad_returnredirect "mapping.tcl"


