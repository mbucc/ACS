# $Id: delete-bookmark-2.tcl,v 3.0.4.1 2000/04/28 15:09:45 carsten Exp $
# delete-bookmark-2.tcl
#
# actually deletes a bookmark
#
# by aure@arsdigita.com and dh@arsdigita.com

set_the_usual_form_variables

# bookmark_id, return_url

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# start error-checking
set exception_text ""
set exception_count 0

if { ![info exists bookmark_id] || [empty_string_p $bookmark_id] } {
    incr exception_count
    append exception_text "<li>No bookmark was specified"
}

# make sure that the user owns the bookmark
set  ownership_query "
        select count(*)
        from   bm_list
        where  owner_id=$user_id
        and bookmark_id=$bookmark_id"
set ownership_test [database_to_tcl_string $db $ownership_query]

if {$ownership_test==0} {
    incr exception_count
    append exception_text "<li>You can not edit this bookmark"
}

# return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set sql_child_delete "
    delete from bm_list 
    where bookmark_id in (select      bookmark_id
                          from        bm_list
			  connect by  prior bookmark_id = parent_id
			  start with  parent_id = $bookmark_id)
    or bookmark_id = $bookmark_id"

if [catch {ns_db dml $db $sql_child_delete} errmsg] {
    ad_return_error "Ouch!" "The database chocked on our delete:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

# send the browser back to the url it was at before the editing process began
ad_returnredirect $return_url










