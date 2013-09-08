ad_page_contract {
    displays a user's portrait to the user him/herself
    offers options to replace it

    @cvs-id index.tcl,v 1.1.2.6 2000/09/22 01:36:30 kevin Exp
    @author philg@mit.edu

    @param user_id
} {
    user_id:naturalnum,notnull
}

ad_maybe_redirect_for_registration

if ![db_0or1row get_user_info {
    select
      u.first_names, 
      u.last_name, 
      gp.portrait_id,
      gp.portrait_upload_date,
      gp.portrait_comment,
      gp.portrait_original_width,
      gp.portrait_original_height,
      gp.portrait_client_file_name
    from users u, general_portraits gp
    where u.user_id = :user_id
      and u.user_id = gp.on_what_id(+)
      and 'USERS' = gp.on_which_table(+)
      and 't' = gp.portrait_primary_p(+)
}] {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
    set widthheight "width=$portrait_original_width height=$portrait_original_height"
} else {
    set widthheight ""
}

if  { [empty_string_p $portrait_id] } {
    set img_html_frag "\[ <i>No portrait has been uploaded for this user.</i> \]"
    set replacement_text "portrait"
    set comment_html_frag ""
} else {
    set img_html_frag "<img $widthheight src=\"/shared/portrait-bits.tcl?[export_url_vars portrait_id]\">"
    set replacement_text "replacement"
    if { [empty_string_p $portrait_comment] } {
      set comment_html_frag "<li><a href=comment-modify.tcl?[export_url_vars user_id]>add a comment</a>\n<p>"
    } else {
      set comment_html_frag "<li><a href=comment-modify.tcl?[export_url_vars user_id]>modify the comment</a>\n<p>"
    }
}

doc_return 200 text/html "[ad_header "Portrait of $first_names $last_name"]

<h2>Portrait of $first_names $last_name</h2>

[ad_admin_context_bar [list "/admin/users//index.tcl" "Users"] [list "../one.tcl?user_id_from_search=14760&first_names_from_search=Uday&last_name_from_search=Mathur&email_from_search=umathur%40arsdigita%2ecom" "$first_names $last_name"] "$first_names's Portrait"]

<hr>

This is the image that we show to other users at [ad_system_name]:<br>
(If you just changed the image, you may need to reload this page to see your changes.)

<br>
<br>

<center>
$img_html_frag
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
<li><a href=\"upload?[export_url_vars user_id]\">upload a $replacement_text</a><p>

$comment_html_frag

<li><a href=\"erase?[export_url_vars user_id]\">erase</a>

</ul>

[ad_footer]
"

