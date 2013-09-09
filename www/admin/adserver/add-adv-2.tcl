# /www/admin/adserver/add-adv-2.tcl

ad_page_contract {
    Target page for add-adv.tcl

    Inserts one row into the advs table. If a row with the same adv_key already exists, 
    the user is notified of the problem, unless _all_ the form inputs are identical to
    the ones in the existing row. In that case or when the insert succeeds, the user is
    redirected to one-adv.tcl

    @param adv_key:notnull
    @param target_url
    @param local_image_p
    @param track_clickthru_p
    @param adv_filename  

    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id add-adv-2.tcl,v 3.1.6.7 2000/11/20 23:55:13 ron Exp
} {
    adv_key:notnull
    target_url:allhtml
    local_image_p
    track_clickthru_p
    adv_filename  
}

db_dml adv_insert_query "
insert into advs 
       (adv_key, target_url, local_image_p, track_clickthru_p, adv_filename) 
select :adv_key, :target_url, :local_image_p, :track_clickthru_p, :adv_filename 
from   dual 
where  not exists (select 1 from advs where adv_key = :adv_key)"

set insert_succ_p [db_string adv_insert_check "
select count(*) 
from   advs 
where  adv_key = :adv_key 
and    target_url = :target_url 
and    local_image_p = :local_image_p
and    track_clickthru_p = :track_clickthru_p 
and    adv_filename = :adv_filename"]

db_release_unused_handles

if { $insert_succ_p } {
    ad_returnredirect "one-adv?[export_url_vars adv_key]"
} else {
    doc_return 200 text/html "
    [ad_admin_header "Adding ad failed"]

    <h2>Adding ad failed</h2>

    [ad_admin_context_bar [list "" "AdServer"] "New Ad"]

    <hr>

    <p> We are sorry. The ad <i>$adv_key</i> could not be added. 
    There already is an ad with the same ad key. 
    <p> Please use the back button on your browser and change the ad key.

    [ad_footer]"
}

