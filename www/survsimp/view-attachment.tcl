# /www/survsimp/view-attachment.tcl
ad_page_contract {

  View the attachment contents of a given response.

  @param  response_id  id of complete survey response submitted by user
  @param  question_id  id of question for which this file was submitted as an answer

  @author jbank@arsdigita.com
  @cvs-id view-attachment.tcl,v 1.1.2.3 2000/07/21 04:04:08 ron Exp
} {

  response_id:integer,notnull
  question_id:integer,notnull

}



set file_type  [db_string get_file_type "select attachment_file_type
from survsimp_question_responses
where response_id = :response_id and question_id = :question_id" -default ""]

if { [empty_string_p $file_type] } {
    ad_return_error "Couldn't find attachment" "Couldn't find an attachment matching the response_id $response_id, question_id $question_id given."
    return
}

ReturnHeaders $file_type

#  This has not been converted to bind variables yet, but for the
#  moment we're still using tcl variable substitution because we
#  are certain that these are integers

db_write_blob return_attachment "select attachment_answer  
from survsimp_question_responses
where response_id = $response_id and question_id = $question_id"

db_release_unused_handles
