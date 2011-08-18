# $Id: delete-dead-links.tcl,v 3.0.4.1 2000/04/28 15:08:24 carsten Exp $
# delete-dead-links.tcl
#
# deletes all occurrences of bookmarks with a dead url
#
# by aure@arsdigita.com

set_the_usual_form_variables 

# deleteable_link

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# get the deleteable links from the form
if {$deleteable_link!=""} {
    catch {nmc_GetCheckboxValues [ns_conn form] {deleteable_link}} deleteable_link
    regsub -all { } $deleteable_link {,} deleteable_link
}

set db [ns_db gethandle]

set sql_delete "
    delete from bm_list
    where owner_id = $user_id
    and url_id in ($deleteable_link)"

# Note: This may break with a huge deleteable_link list, but it is somewhat
# unlikely that someone will have that many dead links and even more unlikely
# that they will check that many checkboxes on the previous page 

if [catch {ns_db dml $db $sql_delete} errmsg] {
    ns_return 200 text/html "<title>Error</title>
    <h1>Error</h1>
    <hr>
    We encountered an error while trying to process this DELETE:
    <pre>$errmsg</pre>
    [ad_admin_footer]
    "
    return
}

ad_returnredirect $return_url
