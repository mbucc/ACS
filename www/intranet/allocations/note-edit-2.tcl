# $Id: note-edit-2.tcl,v 3.0.4.2 2000/04/28 15:11:05 carsten Exp $
# File: /www/intranet/allocations/note-edit-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Writes edit to allocation note to db
# 

set_the_usual_form_variables 

#  allocation_note_start_block, start_block, end_block, note

set db [ns_db gethandle]
ns_db dml $db "update im_start_blocks set note='$QQnote'
where start_block= '$allocation_note_start_block'"

ad_returnredirect "index.tcl?[export_url_vars start_block end_block]"
