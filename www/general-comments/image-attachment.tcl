# $Id: image-attachment.tcl,v 3.0 2000/02/06 03:44:02 ron Exp $
# File:     /general-comments/image-attachment.tcl
# Date:     01/21/2000
# Contact:  philg@mit.edu, tarik@mit.edu
# Purpose:  Present a pretty page with caption and image info with an IMG tag.
#           This page should only get called for image attachments; any other
#           attachments should be sent directly to 
#           /general-comments/attachment/[comment_id]/[filename]
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# comment_id return_url

set db [ns_db gethandle]
set selection [ns_db 1row $db "select one_line_item_desc, file_type, caption, original_width, original_height, client_file_name, users.user_id, users.first_names, users.last_name, users.email, on_what_id
from general_comments, users
where comment_id = $comment_id
and users.user_id = general_comments.user_id"]


set_variables_after_query

ns_return 200 text/html "[ad_header "Image Attachment"]

<h2>Image Attachment</h2>

[ad_context_bar_ws [list $return_url "$one_line_item_desc"] "Image Attachment"]

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


