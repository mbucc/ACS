# /shared/portrait.tcl

ad_page_contract {
    displays a user's portrait to other users

    @author philg@mit.edu
    @creation-date September 26, 1999
    @cvs-id portrait.tcl,v 3.1.2.5 2000/09/22 01:39:18 kevin Exp
} {
    user_id:integer
}

set user_name [db_0or1row get_user_name "select first_names, last_name from users where user_id = :user_id"]

set portrait_p [db_0or1row portrait_check {
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
}]

if { !$portrait_p } {
    ad_return_error "Portrait Unavailable" "We couldn't find a portrait (or this user)"
    return
}

if [empty_string_p $portrait_upload_date] {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for this person."
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

[ad_context_bar_ws_or_index [list "/shared/community-member.tcl?[export_url_vars user_id]" "One Member"] "Portrait"]

<hr>

<br>
<br>

<center>
<img $widthheight src=\"/shared/portrait-bits.tcl?[export_url_vars portrait_id]\">
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
</ul>

[ad_footer]
"
