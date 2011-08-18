# $Id: portrait.tcl,v 3.0 2000/02/06 03:31:22 ron Exp $
# 
# /admin/users/portrait.tcl
#
# by philg@mit.edu on September 26, 1999
#
# offers an admin the option to delete a user's portrait

set_the_usual_form_variables

# user_id 

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select 
  first_names, 
  last_name, 
  portrait_upload_date,
  portrait_comment,
  portrait_original_width,
  portrait_original_height,
  portrait_client_file_name
from users 
where user_id=$user_id"]

if [empty_string_p $selection] {
    ad_return_error "Portrait Unavailable" "We couldn't find a portrait (or this user)"
    return
}

set_variables_after_query

if [empty_string_p $portrait_upload_date] {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for this person."
    return
}

if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
    set widthheight "width=$portrait_original_width height=$portrait_original_height"
} else {
    set widthheight ""
}

ns_return 200 text/html "[ad_admin_header "Portrait of $first_names $last_name"]

<h2>Portrait of $first_names $last_name</h2>

[ad_admin_context_bar [list "one.tcl?[export_url_vars user_id]" "One User"] "Portrait"]

<hr>

<br>
<br>

<center>
<img $widthheight src=\"/shared/portrait-bits.tcl?[export_url_vars user_id]\">
</center>


<br>
<br>

<ul>
<li>Comment:  
<blockquote>
$portrait_comment
</blockquote>
<li>Uploaded:  [util_AnsiDatetoPrettyDate $portrait_upload_date]
<li>Original Name:  $portrait_client_file_name

<p>

<li><a href=\"portrait-erase.tcl?user_id=$user_id\">erase</a>

</ul>

[ad_admin_footer]
"
