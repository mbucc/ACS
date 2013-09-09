# www/admin/general-comments/toggle-approved-p.tcl

ad_page_contract {
    Toggles the approval state of a comment.

    @cvs-id  toggle-approved-p.tcl,v 3.1.6.3 2000/07/29 22:41:46 pihman Exp
    @param comment_id The comment to approve/unapprove
    @param return_url The page to return to after toggling approval

} {
    comment_id:integer
    {return_url index.tcl}
}


db_dml general_comments_toggle_approval_state \
	"update general_comments 
         set approved_p = logical_negation(approved_p) 
         where comment_id = :comment_id"
db_release_unused_handles

ad_returnredirect $return_url

