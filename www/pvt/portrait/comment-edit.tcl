# /www/pvt/portrait/comment-edit.tcl

ad_page_contract {
    screen to edit the comment associated with a user's portrait
    
    @author mbryzek@arsdigita.com
    @creation-date Thu Jun 22 16:11:00 2000
    @cvs-id comment-edit.tcl,v 3.2.2.5 2000/09/22 01:39:12 kevin Exp
}

set user_id [ad_maybe_redirect_for_registration]

set user_name_p [db_0or1row get_user_name {
   select first_names, last_name
     from users
    where user_id = :user_id
}]
set portrait_p [db_0or1row portrait_comment_edit_exists_check {
   select portrait_id, 
	  portrait_upload_date,
	  portrait_comment
     from general_portraits
    where on_what_id = :user_id
      and on_which_table = 'USERS'
      and approved_p = 't'
      and portrait_primary_p = 't'
}]

if { ! $user_name_p } {
    ad_return_error "Account Unavailable" "We can't find you (user-id=$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}


if { ! $portrait_p } {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for you."
    return
}

doc_return  200 text/html "
[ad_header "Edit comment for your portrait"]

<h2>Edit comment for the portrait of $first_names $last_name</h2>

[ad_context_bar_ws [list index "Your Portrait"] "Edit comment"]

<hr>

<blockquote>
<form method=post action=comment-edit-2>
[export_form_vars portrait_id]
Story Behind Photo:<br>
<textarea rows=6 cols=50 wrap=soft name=portrait_comment>
[philg_quote_double_quotes $portrait_comment]
</textarea>

<p>

<center>
<input type=submit value=\"Save comment\">
</center>
</blockquote>
</form>

[ad_footer]
"
