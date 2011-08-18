# /bookmarks/insert-one-2.tcl
#
# by aure@arsdigita.com and dh@arsdigita.com, June 1999
#
#  inserts a single bookmark into the bookmark system.
#
#  Details: 
#   1 splits the 'complete_url' to get the 'host_url'
#   2 checks if 'complete_url' and implicitly 'host_url' are  already in bm_urls  
#            if not,  inserts them into the table 
#   3 inserts the corresponding 'pretty_title', 'bookmark_id', 'parent_id' (along with user_id) 
#     into bm_list
#
# $Id: insert-one-2.tcl,v 3.0.4.3 2000/04/28 15:09:46 carsten Exp $

ad_page_variables {
    parent_id
    complete_url
    local_title
    bookmark_id
    return_url
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# split the url to get the host_url
set host_url [bm_host_url $complete_url]

# check if the 'complete_url' is already in bm_urls
set sql_count_urls "
    select count(*)
    from   bm_urls
    where  complete_url = '$QQcomplete_url' "

set n_complete_urls [database_to_tcl_string $db $sql_count_urls]

# if this url isn't already in the database, get the next 'url_id' and insert the url (complete and host)
# with it.
# if it is already in the database just get the corresponding 'url_id' 

if {$n_complete_urls == "0"} {

    set url_id [database_to_tcl_string $db "select bm_url_id_seq.nextval from dual"]
    ns_db dml $db "
        insert  into  bm_urls
        (url_id, host_url, complete_url)
        values
        ($url_id,'[DoubleApos $host_url]','$QQcomplete_url') "

} else {

    set url_id [database_to_tcl_string $db "select url_id from bm_urls where complete_url='$QQcomplete_url'"]

}
   
set insert "
    insert into bm_list
    (bookmark_id, owner_id, url_id, local_title, parent_id, creation_date)
    values
    ($bookmark_id, $user_id, $url_id,'[DoubleApos $local_title]', [ns_dbquotevalue $parent_id], sysdate)"

if [catch {ns_db dml $db $insert} errmsg] {
    # check and see if this was a double click

    set dbclick_p [database_to_tcl_string $db "select count(*) from bm_list where bookmark_id=$bookmark_id"]

    if {$dbclick_p == "1"} {

	ad_returnredirect $return_url
	return

    } else {

	ad_return_complaint 1 "<li> There was an error making this insert into the database. $errmsg"
	return 

    }
}

ns_db dml $db "end transaction"

ad_returnredirect $return_url











