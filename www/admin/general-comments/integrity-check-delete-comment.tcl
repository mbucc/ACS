# www/admin/general-comments/integrity-check-delete-comment.tcl

ad_page_contract {
    Deletes an orphaned general comment

    @cvs-id  integrity-check-delete-comment.tcl,v 3.1.6.1 2000/07/08 02:59:35 mbryzek Exp $
    @param comment_ud The comment to delete

} {
    comment_id:integer
}


db_dml general_comment_delete \
	"delete from general_comments where comment_id = :comment_id"
db_release_unused_handles
ad_returnredirect "integrity-check.tcl"
