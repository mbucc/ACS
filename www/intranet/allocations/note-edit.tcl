# $Id: note-edit.tcl,v 3.1.4.1 2000/03/17 08:22:48 mbryzek Exp $
# File: /www/intranet/allocations/note-edit.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Lets you edit an allocation note
# 

set_the_usual_form_variables 

# allocation_note_start_block
# maybe start_block, end_note

set db [ns_db gethandle]
set note [database_to_tcl_string $db "select note from im_start_blocks
where start_block = '$allocation_note_start_block'"]

set page_title  "Edit note for $allocation_note_start_block"
set context_bar "[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Project allocations"] "Edit note"]"

ns_return 200 text/html " 
[ad_partner_header]
<form action=note-edit-2.tcl method=post>
[export_form_vars start_block end_block allocation_note_start_block]
<table>
<th valign=top>Note:</th> 
<td><textarea name=note cols=50 rows=5>[ns_quotehtml $note]</textarea></td>
</tr>
</table>
<center>
<input type=submit name=submit value=Submit>
</center>
</form>
<p>
[ad_partner_footer]"
