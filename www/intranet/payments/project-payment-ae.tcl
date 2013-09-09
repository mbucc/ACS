# /www/intranet/payments/project-payment-ae.tcl

ad_page_contract {
    Purpose: form to enter payments for a project

    @param group_id Must have this if we're adding a payment
    @param payment_id Must have this if we're editing a payment

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id project-payment-ae.tcl,v 3.7.2.7 2001/01/12 19:56:23 khy Exp
} {
    { group_id:naturalnum "" }
    { payment_id:naturalnum "" }
}

if { [empty_string_p $payment_id] && [empty_string_p $group_id] } {
    ad_return_error "Missing parameter" "Either group_id or payment_id must be specified"
    return
}

set caller_id [ad_maybe_redirect_for_registration]

set fee_type_list [ad_parameter FeeTypes intranet]

if {[empty_string_p $payment_id]} {
    set project_name [db_string get_project_name \
	    "select ug.group_name 
               from user_groups ug
              where ug.group_id = :group_id"]

    set add_delete_text 0
    set payment_id [db_nextval "im_project_payment_id_seq"]
    set page_title "Add payment  for $project_name" 
    set context_bar [ad_context_bar_ws [list [im_url_stub]/projects/ "Projects"] [list [im_url_stub]/projects/view?[export_url_vars group_id] "One project"] [list index?[export_url_vars group_id] Payments] "Add payment"]
    set button_name "Add payment"

    # Let's default start_block to something close to today
    if { ![db_0or1row nearest_start_block_select {
	select to_char(min(sb.start_block),'Month DD, YYYY') as start_block
	  from im_start_blocks sb
	where sb.start_block >= trunc(sysdate)}] } {
	    ad_return_error "Start block error" "The intranet start blocks are either undefined or we do not have a start block for this week or later into the future."
	    return
	}
	   
} else {
    db_0or1row get_payment_info \
	    "select ug.group_name as project_name, ug.group_id,
               to_char(p.start_block,'Month DD, YYYY') as start_block, 
               p.fee, p.fee_type, p.note
             from user_groups ug, im_project_payments p
             where p.group_id = ug.group_id
             and p.payment_id = :payment_id"
 
    set add_delete_text 1
    set page_title "Edit payment for $project_name"
    set context_bar [ad_context_bar_ws [list [im_url_stub]/projects/ "Projects"] [list [im_url_stub]/projects/view?[export_url_vars group_id] "One project"] [list index?[export_url_vars group_id] Payments] "Edit payment"]
    set button_name "Update"
}


set page_body "

<form action=project-payment-ae-2 method=post>
[export_form_vars group_id]
[export_form_vars -sign payment_id]

<TABLE CELLPADDING=5>

<TR>
<TD ALIGN=RIGHT>Start date of work:</TD>
<TD> 
<select name=start_block>
[db_html_select_options -select_option $start_block start_date_list \
	"select to_char(start_block,'Month DD, YYYY'), start_block 
         from im_start_blocks 
         order by start_block asc"] 
</select>
</TD>
</TR>

<tr>
<td align=right>Fee:</td>
<td>
<input type=text name=fee [export_form_value fee]>
</td>
</tr>

<TR>
<TD ALIGN=RIGHT>Fee type:</TD>
<TD><select name=fee_type>
[ad_generic_optionlist  $fee_type_list $fee_type_list [value_if_exists fee_type]]
</select>
</TD>
</TR>

</TABLE>

<P>Note:<BR>
<BLOCKQUOTE>
<TEXTAREA NAME=note COLS=45 ROWS=5 wrap=soft>[ad_quotehtml [value_if_exists note]]
</TEXTAREA>
</BLOCKQUOTE>

<P><CENTER>
<INPUT TYPE=Submit Value=\" $button_name \">
</CENTER>

</FORM>

[util_decode $add_delete_text 0 "" "<ul>
  <li> <a href=delete?[export_url_vars payment_id]>Delete this payment</a>
</ul>
"]

"

doc_return  200 text/html [im_return_template]
