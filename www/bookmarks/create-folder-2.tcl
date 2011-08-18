#
# /bookmarks/create-folder-2.tcl
#
# create a folder to store bookmarks in
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# $Id: create-folder-2.tcl,v 3.0.4.3 2000/04/28 15:09:45 carsten Exp $
#
set_the_usual_form_variables 
# ad_page_variables {
#    local_title
#    parent_id
#    bookmark_id
#    return_url
#}

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]]"
    return
}

if {![info exists parent_id]} {
    set parent_id "null"
}

if {[empty_string_p $local_title]} {
    set local_title "unnamed"
}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"


set insert "
insert into bm_list
(bookmark_id, owner_id, local_title, parent_id, creation_date, folder_p, closed_p)
values
($bookmark_id, $user_id, '[DoubleApos $local_title]', [ns_dbquotevalue $parent_id], sysdate, 't', 'f')
"
if [catch {ns_db dml $db $insert} errmsg] {
# check and see if this was a double click
    set dbclick_p [database_to_tcl_string $db "select count(*) from bm_list where bookmark_id=$bookmark_id"]
    if {$dbclick_p == "1"} {
	ad_returnredirect $return_url
	return
    } else {
	ad_return_complaint 1 "<li> There was an error making this insert into the database. 
	<pre>$errmsg"
	return 
    }
}

bm_set_hidden_p $db $user_id
bm_set_in_closed_p $db $user_id

ns_db dml $db "end transaction"

ad_returnredirect $return_url







