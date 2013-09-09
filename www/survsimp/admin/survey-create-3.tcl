# /www/survsimp/admin/survey-create-3.tcl
ad_page_contract {

  Displays confirmation page for new survey creation or, if we
  just arrived from it, actually creates new survey.

  @param  survey_id    id of survey to be created
  @param  name         new survey title
  @param  short_name   new survey short tag
  @param  description  new survey description
  @param  desc_html    whether the description is provided in HTML or not
  @param  checked_p    t if we arrived from confirmation page

  @author philg@mit.edu
  @date   February 9, 2000
  @cvs-id survey-create-3.tcl,v 1.1.2.1 2001/01/11 23:53:50 khy Exp

} {

  survey_id:integer,naturalnum,verify
  name
  short_name
  description:html
  desc_html
  {checked_p "f"}

}


set exception_count 0
set exception_text ""

if { [empty_string_p $short_name] } {
    incr exception_count
    append exception_text "<li>You didn't enter a short name for this survey.\n"
} else {
    # make sure the short name isn't used somewhere else

    set short_name_used_p [db_string short_name_uniqueness_check "
select count(short_name)
from survsimp_surveys
where lower(short_name) = lower(:short_name)"]

    if {$short_name_used_p > 0} {
	incr exception_count
	append exception_text "<li>This short name, $short_name, is already in use.\n"
    }
}

if { [empty_string_p $name] } {
    incr exception_count
    append exception_text "<li>You didn't enter a name for this survey.\n"
}

if { [empty_string_p $description] } {
    incr exception_count
    append exception_text "<li>You didn't enter a description for this survey.\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set user_id [ad_verify_and_get_user_id]
	
# make sure the short_name is unique
   
if {[string compare $desc_html "plain"] == 0} {
    set description_html_p "f"
} else {
    set description_html_p "t"
}

db_dml create_survey "insert into survsimp_surveys( 
			survey_id   , 
			name	    , 
			short_name  , 
			description , 
			description_html_p, 
			creation_user)
		    values (
			:survey_id  , 
			:name	    , 
			:short_name , 
			:description, 
			:description_html_p, 
			:user_id)"
    
db_release_unused_handles
ad_returnredirect "question-add.tcl?survey_id=$survey_id"
