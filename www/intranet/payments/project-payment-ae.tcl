# $Id: project-payment-ae.tcl,v 3.1.4.1 2000/03/17 08:23:08 mbryzek Exp $
# File: /www/intranet/payments/project-payment-ae.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: form to enter payments for a project
#

set_the_usual_form_variables 0

# group_id
# maybe payment_id

set caller_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set fee_type_list [ad_parameter FeeTypes intranet]

set db [ns_db gethandle]

set project_name [database_to_tcl_string $db "select 
group_name from user_groups ug
where group_id = $group_id"]


if {![info exists payment_id] || [empty_string_p $payment_id]} {
    set payment_id [database_to_tcl_string $db "select im_project_payment_id_seq.NEXTVAL from dual"]
    set page_title "Add payment  for $project_name" 
    set button_name "Add payment"

} else {
    set selection [ns_db 0or1row $db "select * from im_project_payments where
payment_id = $payment_id"] 
    if ![empty_string_p $selection] {
        set_variables_after_query
    }
    set page_title "Edit payment for $project_name"
    set button_name "Update"
}

set context_bar "[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "../projects/index.tcl" "Projects"] [list "../projects/view.tcl?[export_url_vars group_id]"  "One project"] "Payment"]"

set page_body "

<form action=project-payment-ae-2.tcl method=post>
[export_form_vars group_id payment_id]

<TABLE CELLPADDING=5>

<TR>
<TD ALIGN=RIGHT>Start date of work:</TD>
<TD> 
<select name=start_block>
[ad_db_optionlist $db "select to_char(start_block,'Month DD, YYYY'), start_block from im_start_blocks order by start_block asc" [value_if_exists start_block]]
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
<TEXTAREA NAME=note COLS=45 ROWS=5 wrap=soft>[ns_quotehtml [value_if_exists note]]</TEXTAREA>
</BLOCKQUOTE>

<P><CENTER>
<INPUT TYPE=Submit Value=\" $button_name \">
</CENTER>

</FORM>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]
