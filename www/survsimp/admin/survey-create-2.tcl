# /www/survsimp/admin/survey-create-2.tcl
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
  @cvs-id survey-create-2.tcl,v 1.6.2.6 2001/01/11 23:53:49 khy Exp

} {
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


    set survey_id [db_string next_survey_id "select survsimp_survey_id_sequence.nextval from dual"]
    set whole_page "[ad_header "Confirm New Survey Description"]
    
    <h2>Confirm New Survey Description</h2>
    
    [ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] "Confirm New Survey Description"]
    
    <hr>
    
    Here is how your survey description will appear:
    <blockquote><p>"

    switch $desc_html {
	"html" {
	    append whole_page "$description"
	}
	
	"pre" {
	    regsub "\[ \012\015\]+\$" $description {} description
	    set description "<pre>[ns_quotehtml $description]</pre>"
	    append whole_page "$description"
	}

	default {
	    append whole_page "[util_convert_plaintext_to_html $description]"
	}
    }
    
    append whole_page "<form method=post action=\"survey-create-3\">
    [export_form_vars name short_name description desc_html]
    [export_form_vars -sign survey_id]
    <input type=hidden name=checked_p value=\"t\">
    <br><center><input type=submit value=\"Confirm\"></center>
    </form>

    </blockquote>

    <font size=-1 face=\"verdana, arial, helvetica\">
    Note: if the text above has a bunch of visible HTML tags then you probably
    should have selected \"HTML\" rather than \"Plain Text\". If it is all smashed together
    and you want the original line breaks saved then choose \"Preformatted Text\".
    Use your browser's Back button to return to the submission form.
    </font>
    
    [ad_footer]"
    
    
    doc_return  200 text/html $whole_page
    return


