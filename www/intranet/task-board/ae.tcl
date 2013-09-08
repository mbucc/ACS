# /www/intranet/task-board/ae.tcl

ad_page_contract {
    
    posts a new tasks on the task board
    
    @param task_id If specified, we edit the task. If not specified, we create a new task

    @author Tracy Adams (teadams@arsdigita.com) 
    @creation-date July 17th, 2000
    @cvs-id ae.tcl,v 1.2.2.3 2001/01/12 17:06:26 khy Exp

} {
    { task_id:integer "" }
    { return_url "" }

}

set user_id [ad_maybe_redirect_for_registration]

if { ![empty_string_p $task_id] } {
    set page_title "Edit task"
    set context_bar [ad_context_bar_ws  [list "index" "Task Board"] [list one?[export_url_vars task_id] "One Task"] "Edit Task"]

    # Select out current values to put them in the form
    if { ![db_0or1row task_information \
	    "select tb.task_name, tb.body, tb.next_steps, tb.time_id, 
                    tb.expiration_date, tb.poster_id
               from intranet_task_board tb
              where tb.task_id = :task_id"] } {

		  ad_return_error "Task doesn't exist" "Task $task_id could not be found"
		  return
    }

    # ONly the posting user or an admin can edit/delete a task
    if { $poster_id != $user_id && ![im_is_user_site_wide_or_intranet_admin $user_id] } {
	ad_return_error "You can't edit this task" "You do not have permission to edit this task. Only the person who posted the task or an administrator can edit it."
	return
    }


} else {

    set page_title "Add a Task"
    set context_bar [ad_context_bar_ws  [list "index" "Task Board"] "Post Task"]

    db_1row next_task_id_and_expiration_date \
	    "select intranet_task_board_id_seq.nextval as task_id,
                    sysdate + 7 as expiration_date
               from dual"

}

set page_content "
[im_header]

<form method=post action=\"ae-2\">
[export_form_vars return_url]
[export_form_vars -sign task_id]

<table>

<tr><th>Task name </td><td><input type=text size=40 name=task_name [export_form_value task_name]></th></tr>

<tr><th>Task description</td><td><textarea cols=60 rows=6 wrap=soft name=body>[philg_quote_double_quotes [value_if_exists body]]</textarea></th></tr>

<tr><th>Next steps</td><td><textarea cols=60 rows=3 wrap=soft name=next_steps>[philg_quote_double_quotes [value_if_exists next_steps]]</textarea></th></tr>

<tr><th>Time</th><td><select name=category_id>
  [db_html_select_value_options -select_option [value_if_exists time_id] task_board_categories "select category_id, category from categories where category_type = 'Intranet Task Board Time Frame'"]</select></td></tr>

<tr><th>Post until <td>[philg_dateentrywidget expiration $expiration_date]
</table>
<br>
<center>
<input type=\"submit\" value=\"Submit\">
</center>
</form>
[im_footer]
"

doc_return  200 text/html $page_content