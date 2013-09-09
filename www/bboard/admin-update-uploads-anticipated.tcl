# /www/bboard/admin-update-uploads-anticipated.tcl
ad_page_contract {
    Updates the file upload info

    @cvs-id admin-update-uploads-anticipated.tcl,v 3.2.2.5 2000/10/04 02:32:33 jmileham Exp
} {
    uploads_anticipated
    topic_id:notnull,integer
    topic
}

# -----------------------------------------------------------------------------

 
db_1row maintainer "
select primary_maintainer_id from bboard_topics where topic_id = :topic_id"

if {[bboard_admin_authorization] == -1} {
    return
}

db_dml topics_update "
update bboard_topics 
set    uploads_anticipated = :uploads_anticipated
where  topic_id = :topic_id" 

ad_returnredirect "admin-home.tcl?[export_url_vars topic topic_id]"
