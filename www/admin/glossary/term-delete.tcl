# $Id: term-delete.tcl,v 3.0.4.1 2000/04/28 15:09:07 carsten Exp $
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

# term

set exception_count 0
set exception_text ""

set db [ns_db gethandle]

if { ![info exists term] || [empty_string_p $QQterm]} {
    incr exception_count
    append exception_text "<li>You somehow got here without specifying a term to delete."
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

if [catch { ns_db dml $db "delete from glossary 
where term = '$QQterm'" } errmsg] {
    # update failed
    ad_return_error "Delete Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

ad_returnredirect "index.tcl"
