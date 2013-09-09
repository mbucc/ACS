# www/comments/image-attachment.tcl

ad_page_contract {
    Present a pretty page with caption and image info with an IMG tag.

    @param comment_id
    @cvs-id image-attachment.tcl,v 3.1.6.5 2000/09/22 01:37:16 kevin Exp
} {
    {comment_id:naturalnum,notnull}
}


set selection [db_0or1row comments_image_attach_comment_data_get {
    select url_stub, nvl(page_title, url_stub) as page_title, file_type, caption, 
           original_width, original_height, client_file_name, 
           users.user_id, users.first_names, users.last_name, users.email
    from comments, users, static_pages
    where comment_id = :comment_id
    and users.user_id = comments.user_id
    and static_pages.page_id = comments.page_id
}]

if {$selection == 0} {
    ad_return_complaint "Invalid comment id" "Command id could not be found."
    db_release_unused_handles
    return
}

doc_return  200 text/html "[ad_header "Image Attachment"]

<h2>Image Attachment</h2>

for comment on <a href=\"$url_stub\">$page_title</a>

<hr>

<center>
<i>$caption</i>
<p>
<img src=\"attachment/$comment_id/$client_file_name\" width=$original_width height=$original_height>
</center>

<hr>
<a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a>
</body>
</html>
"


