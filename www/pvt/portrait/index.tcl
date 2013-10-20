# /pvt/portrait/index.tcl

ad_page_contract {
    displays a user's portrait to the user him/herself
    offers options to replace it

    @author philg@mit.edu
    @creation-date September 26, 1999
    @cvs-id index.tcl,v 3.2.2.5 2000/09/22 01:39:13 kevin Exp
}

set user_id [ad_maybe_redirect_for_registration]

if { ![db_0or1row user_check {
    select first_names, last_name
      from users
      where user_id = :user_id
}] } {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

#         approved_p		general_portraits      result
#         ---------- 		------------------    ----------------------
#    1        't'   		no record at all       error message
#    2        'f'   		no record at all       error message
#
#    3        't'   		approved_p = 'f'       error message
#    4        'f'   		approved_p = 'f'       waiting approval message
#
#    5        't'   		approved_p = 't'       OK
#    6        'f'   		approved_p = 't'       OK

set approved_p [util_decode [ad_parameter DefaultUploadApprovalPolicy "general-portraits"] "open" "t" "f"]


# Cases 1 and 2: no portrait record at all.
if { ![db_0or1row portrait_check {
   select portrait_id,
	  portrait_upload_date,
	  portrait_comment,
	  portrait_original_width,
	  portrait_original_height,
	  portrait_client_file_name
     from general_portraits
    where on_what_id = :user_id
      and on_which_table = 'USERS'
      and portrait_primary_p = 't'
}] } {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for you."
    return
}

if { ![db_0or1row portrait_check {
   select portrait_id,
	  portrait_upload_date,
	  portrait_comment,
	  portrait_original_width,
	  portrait_original_height,
	  portrait_client_file_name
     from general_portraits
    where on_what_id = :user_id
      and on_which_table = 'USERS'
      and approved_p = 't'
      and portrait_primary_p = 't'
}] } {
    # Case 3: Uploads are open, but for some reason portrait is not approved.
    # Case 4: Uploads are not open and portrait is not approved.
    doc_return  200 text/html "
    [ad_header "Portrait of $first_names $last_name"]

    <h2>Portrait of $first_names $last_name</h2>

    [ad_context_bar_ws "Your Portrait"]

    <hr>

    <p>
    You won't be able to see your portrait until the site admin approves it
    (we've had some abuse of the approval-free uploads).
    </p>

    <br>

    Data:

    <ul>
    <li>Uploaded:  [util_AnsiDatetoPrettyDate $portrait_upload_date]
    <li>Original Name:  $portrait_client_file_name
    <li>Comment: [util_decode $portrait_comment "" "" "
    <blockquote>
    $portrait_comment
    </blockquote>"]

    </ul>

    Options:

    <ul>
    <li><a href=comment-edit>edit your comment</a>
    <li><a href=\"upload\">upload a replacement</a>

    <p>

    <li><a href=\"erase\">erase</a>

    </ul>

    [ad_footer]
    "
    return
}
if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
    set widthheight "width=$portrait_original_width height=$portrait_original_height"
} else {
    set widthheight ""
}

doc_return  200 text/html "
[ad_header "Portrait of $first_names $last_name"]

<h2>Portrait of $first_names $last_name</h2>

[ad_context_bar_ws "Your Portrait"]

<hr>

This is the image that we show to other users at [ad_system_name]:

<br>
<br>

<center>
<img $widthheight src=\"/shared/portrait-bits?[export_url_vars portrait_id]\">
</center>

Data:

<ul>
<li>Uploaded:  [util_AnsiDatetoPrettyDate $portrait_upload_date]
<li>Original Name:  $portrait_client_file_name
<li>Comment: [util_decode $portrait_comment "" "" "
<blockquote>
$portrait_comment
</blockquote>"]

</ul>

Options:

<ul>
<li><a href=comment-edit>edit your comment</a>
<li><a href=\"upload\">upload a replacement</a>

<p>

<li><a href=\"erase\">erase</a>

</ul>

[ad_footer]
"
