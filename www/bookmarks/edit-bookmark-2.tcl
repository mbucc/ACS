# $Id: edit-bookmark-2.tcl,v 3.0.4.1 2000/04/28 15:09:46 carsten Exp $
# edit-bookmark-2.tcl
#
# edit a bookmark in your bookmark list
#
# by aure@arsdigita.com and dh@arsdigita.com

set_the_usual_form_variables

# local_title, complete_url, bookmark_id, parent_id, return_url

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# start error-checking
set exception_text ""
set exception_count 0

if {(![info exists bookmark_id])||([empty_string_p $bookmark_id])} {
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

if { ![info exists parent_id] || [empty_string_p $parent_id] } {
    set parent_id "null"
}


ns_db dml $db "begin transaction"

# if the bookmark to edit is a folder, complete_url won't be defined
if ![info exists complete_url] {

    # this is a folder so edit its name
    set sql_update "
         update  bm_list
         set     local_title = '[DoubleApos $local_title]',
                 private_p = '$private_p',
                 parent_id = $parent_id
         where   owner_id = $user_id
         and     bookmark_id = $bookmark_id"
    ns_db dml $db $sql_update

} else {

    # entry is a bookmark - need to update both name and url

    set host_url [bm_host_url $complete_url]
    
    # check to see if we already have the url in our database
    set url_query "select url_id
                   from   bm_urls
                   where  complete_url = '[DoubleApos $complete_url]'"
    set url_id [database_to_tcl_string_or_null  $db $url_query]
    
    # if we don't have the url, then insert the url into the database
    if {[empty_string_p $url_id]} { 
	set url_id [database_to_tcl_string $db "select bm_url_id_seq.nextval from dual"]
	ns_db dml $db "    
	insert into bm_urls 
	(url_id, host_url, complete_url)
	values
	($url_id, '[DoubleApos $host_url]', '[DoubleApos $complete_url]')"
    }
                    
# have added the url if needed - now just update the name

    set sql_update "
        update  bm_list
        set     local_title = '[DoubleApos $local_title]',
                url_id = $url_id,
                private_p = '$private_p',
                parent_id = $parent_id
        where   bookmark_id = $bookmark_id"

    ns_db dml $db $sql_update
}


bm_set_hidden_p $db $user_id
bm_set_in_closed_p $db $user_id

ns_db dml $db "end transaction"

# send the user back to where they came from before editing began
ad_returnredirect $return_url




