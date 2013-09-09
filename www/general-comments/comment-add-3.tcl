# /www/general-comments/comment-add-3.tcl
ad_page_contract {
    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000
    @cvs-id comment-add-3.tcl,v 3.4.2.6 2000/09/22 01:38:01 kevin Exp
} {
    {scope ""}
    {group_id ""}
    {on_which_group ""}
    comment_id
    {content:html ""}
    html_p
    item
    module
    {one_line ""}
    {return_url ""}
    on_which_table
    on_what_id
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

if { [empty_string_p $scope] } {
    set scope "public"
}


# assign necessary data for insert
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set originating_ip [ns_conn peeraddr]



# Get the default approval policy for the site
set approval_policy [ad_parameter DefaultCommentApprovalPolicy]

# If there is a different approval policy for the module, override
# the site approval policy
set approval_policy [ad_parameter CommentApprovalPolicy $module $approval_policy]

if {$approval_policy == "open"} {
    set approved_p "t"

    set result_text "
Your comment is now in the database.  You <a
href=\"$return_url\">return to the original page</a> to see it in
context.
"

} else {
    set approved_p "f"

    set result_text "
Your comment is now in the database.  After it is approved by the administrator, you will see it on <a
href=\"$return_url\">the original page</a>.
"

}

if [catch {
ad_general_comment_add $comment_id $on_which_table $on_what_id $item $content $user_id  $originating_ip $approved_p $html_p $one_line
} errmsg] {
    # Oracle choked on the insert
     if { [db_string comment_check "select count(*) from general_comments where comment_id = :comment_id" -bind [ad_tcl_vars_to_ns_set comment_id]] == 0  } { 
	# there was an error with comment insert other than a duplication
	ad_return_error "Error in inserting comment" "We were unable to insert your comment in the database.  Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
        return
     }
}

# either we were successful in doing the insert or the user hit submit
# twice and we don't really care

if ![ad_parameter AcceptAttachmentsP "general-comments" 0] {
    # we don't accept attachments, so return immediatel
    ad_returnredirect $return_url
    return
} 

doc_return  200 text/html "[ad_header "Comment inserted"]

<h2>Comment Inserted</h2>

[ad_context_bar_ws [list $return_url $item] "Comment Inserted"]

<hr>

$result_text

<P>

Alternatively, you can attach a
file to your comment.  This file can be a document, a photograph, or
anything else on your desktop computer.

<form enctype=multipart/form-data method=POST action=\"upload-attachment\">
[export_form_vars comment_id return_url]
<blockquote>
<table>
<tr>
<td valign=top align=right>Filename: </td>
<td>
<input type=file name=upload_file size=20><br>
<font size=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".</font>
</td>
</tr>
<tr>
<td valign=top align=right>Caption</td>
<td><input size=30 name=caption>
<br>
<font size=-1>(leave blank if this isn't a photo)</font>
</td>
</tr>
</table>
<p>
<center>
<input type=submit value=\"Upload\">
</center>
</blockquote>
</form>

[ad_footer]
"
