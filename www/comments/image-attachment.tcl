# $Id: image-attachment.tcl,v 3.0 2000/02/06 03:37:16 ron Exp $
# Present a pretty page with caption and image info with an IMG tag.
# This page should only get called for image attachments; any other
# attachments should be sent directly to 
# /comments/attachment/[comment_id]/[filename]

# Stolen from general_comments.

set_the_usual_form_variables
# comment_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select url_stub, nvl(page_title, url_stub) as page_title, file_type, caption, original_width, original_height, client_file_name, users.user_id, users.first_names, users.last_name, users.email
from comments, users, static_pages
where comment_id = $comment_id
and users.user_id = comments.user_id
and static_pages.page_id = comments.page_id"]

set_variables_after_query

ns_return 200 text/html "[ad_header "Image Attachment"]

<h2>Image Attachment</h2>

for comment on <a href=\"$url_stub\">$page_title</a>

<hr>

<center>
<i>$caption</i>
<p>
<img src=\"attachment/$comment_id/$client_file_name\" width=$original_width height=$original_height>
</center>

<hr>
<a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a>
</body>
</html>
"


