# $Id: index.tcl,v 3.0 2000/02/06 03:53:46 ron Exp $
# 
# /pvt/portrait/index.tcl
#
# by philg@mit.edu on September 26, 1999
#
# displays a user's portrait to the user him/herself
# offers options to replace it

ad_maybe_redirect_for_registration

set user_id [ad_verify_and_get_user_id]

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
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

set_variables_after_query

if [empty_string_p $portrait_upload_date] {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for you."
    return
}

if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
    set widthheight "width=$portrait_original_width height=$portrait_original_height"
} else {
    set widthheight ""
}

ns_return 200 text/html "[ad_header "Portrait of $first_names $last_name"]

<h2>Portrait of $first_names $last_name</h2>

[ad_context_bar_ws "Your Portrait"]

<hr>

This is the image that we show to other users at [ad_system_name]:

<br>
<br>

<center>
<img $widthheight src=\"/shared/portrait-bits.tcl?[export_url_vars user_id]\">
</center>

Data:

<ul>
<li>Uploaded:  [util_AnsiDatetoPrettyDate $portrait_upload_date]
<li>Original Name:  $portrait_client_file_name
<li>Comment:  
<blockquote>
$portrait_comment
</blockquote>
</ul>

Options:

<ul>
<li><a href=\"upload.tcl\">upload a replacement</a>

<p>

<li><a href=\"erase.tcl\">erase</a>

</ul>

[ad_footer]
"
