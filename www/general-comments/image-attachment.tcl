ad_page_contract {
    Purpose:  Present a pretty page with caption and image info with an IMG tag.
              This page should only get called for image attachments; any other
              attachments should be sent directly to 
              /general-comments/attachment/[comment_id]/[filename]

    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000
    @cvs-id image-attachment.tcl,v 3.2.2.5 2000/09/22 01:38:01 kevin Exp
} {
    {scope ""}
    {group_id ""}
    {on_which_group ""}
    comment_id
    return_url
}

db_1row comment_data_get {
    select one_line_item_desc, file_type, caption, original_width, original_height, client_file_name, 
           users.user_id, users.first_names, users.last_name, users.email, on_what_id
    from general_comments, users
    where comment_id = :comment_id
    and users.user_id = general_comments.user_id
}

db_release_unused_handles


if { ![empty_string_p $original_width] && ![empty_string_p $original_height] } {
    set width_and_height "width=$original_width height=$original_height"
} else {
    set width_and_height {}
}

doc_return  200 text/html "[ad_header "Image Attachment"]

<h2>Image Attachment</h2>

[ad_context_bar_ws [list $return_url "$one_line_item_desc"] "Image Attachment"]

<hr>

<center>
<i>$caption</i>
<p>
<img src=\"attachment/$comment_id/$client_file_name\" $width_and_height>
</center>

<hr>
<a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a>
</body>
</html>
"

