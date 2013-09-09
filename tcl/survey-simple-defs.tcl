# /tcl/survey-simple-defs.tcl
ad_library {

  Support procs for simple survey module, most important being
  survsimp_question_display which generates a question widget based
  on data retrieved from database.

  @author philg@mit.edu on
  @author teadams@mit.edu
  @date   February 9, 2000
  @cvs-id survey-simple-defs.tcl,v 1.29.2.5 2000/07/19 20:11:24 seb Exp

}


ns_share -init {set ad_survsimp_filters_installed_p 0} ad_survsimp_filters_installed_p

if {!$ad_survsimp_filters_installed_p} {
    set ad_survsimp_filters_installed_p 1
    ad_register_filter preauth HEAD /survsimp/admin/* survsimp_security_checks_admin
    ad_register_filter preauth HEAD /survsimp/*       survsimp_security_checks
    ad_register_filter preauth GET /survsimp/admin/* survsimp_security_checks_admin
    ad_register_filter preauth GET /survsimp/*       survsimp_security_checks
    ad_register_filter preauth POST /survsimp/admin/* survsimp_security_checks_admin
    ad_register_filter preauth POST /survsimp/*       survsimp_security_checks
}

# we don't want anyone filling out surveys unless they are 
# registered
proc survsimp_security_checks {args why} {
    if { [ad_verify_and_get_user_id] == 0 } {
	ad_redirect_for_registration
	# tells AOLserver to abort the thread
	return filter_return
    } else {	
	# this is a verified authorized user
	return filter_ok
    }
}

# Checks if user is logged in, AND is a member of the survsimp admin group
proc survsimp_security_checks_admin {args why} {
    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	ad_redirect_for_registration
	# tells AOLserver to abort the thread
	return filter_return
    } 

    if {![ad_administration_group_member survsimp "" $user_id] && ![ad_administrator_p $user_id]} {
	ad_return_error "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
	
    return filter_ok
}

proc_doc survsimp_question_display { question_id {edit_previous_response_p "f"} } "Returns a string of HTML to display for a question, suitable for embedding in a form. The form variable is of the form \"response_to_question.\$question_id" {
    set element_name "response_to_question.$question_id"

    db_1row survsimp_question_properties "
select
  survey_id,
  sort_key,
  question_text,
  abstract_data_type,
  required_p,
  active_p,
  presentation_type,
  presentation_options,
  presentation_alignment,
  creation_user,
  creation_date
from
  survsimp_questions
where
  question_id = :question_id"
    
    set html $question_text
    if { $presentation_alignment == "below" } {
	append html "<br>"
    } else {
	append html " "
    }

    set user_value ""

    if {$edit_previous_response_p == "t"} {
 	set user_id [ad_get_user_id]

 	set prev_response_query "select	
	  choice_id,
	  boolean_answer,
	  clob_answer,
	  number_answer,
 	  varchar_answer,
	  date_answer,
          attachment_file_name
   	  from survsimp_question_responses
 	  where question_id = :question_id
             and response_id = (select max(response_id) from survsimp_responses r, survsimp_questions q
   	                       where q.question_id = :question_id
                       	         and r.user_id = :user_id
 	                         and q.survey_id = r.survey_id)"

	set count 0
	db_foreach survsimp_response $prev_response_query {
	    incr count
	    
	    if {$presentation_type == "checkbox"} {
		set selected_choices($choice_id) "t"
	    }
	} if_no_rows {
	    set choice_id 0
	    set boolean_answer ""
	    set clob_answer ""
	    set number_answer ""
	    set varchar_answer ""
	    set date_answer ""
            set attachment_file_name ""
	}
    }

    switch -- $presentation_type {
        "upload_file"  {
	    if {$edit_previous_response_p == "t"} {
		set user_value $attachment_file_name
	    }
	    append html "<input type=file name=$element_name $presentation_options>"
	}
	"textbox" {
	    if {$edit_previous_response_p == "t"} {
		if {$abstract_data_type == "number" || $abstract_data_type == "integer"} {
		    set user_value $number_answer
		} else {
		    set user_value $varchar_answer
		}
	    }

	    append html "<input type=text name=$element_name value=\"[philg_quote_double_quotes $user_value]\" [ad_decode $presentation_options "large" "size=70" "medium" "size=40" "size=10"]>"
	}
	"textarea" {
	    if {$edit_previous_response_p == "t"} {
		if {$abstract_data_type == "number" || $abstract_data_type == "integer"} {
		    set user_value $number_answer
		} elseif { $abstract_data_type == "shorttext" } {
		    set user_value $varchar_answer
		} else {
		    set user_value $clob_answer
		}
	    }

	    append html "<textarea name=$element_name $presentation_options>$user_value</textarea>" 
	}
	"date" {
	    if {$edit_previous_response_p == "t"} {
		set user_value $date_answer
	    }

	    append html "[ad_dateentrywidget $element_name $user_value]" 
	}
	"select" {
	    if { $abstract_data_type == "boolean" } {
		if {$edit_previous_response_p == "t"} {
		    set user_value $boolean_answer
		}

		append html "<select name=$element_name>
 <option value=\"\">Select One</option>
 <option value=\"t\" [ad_decode $user_value "t" "selected" ""]>True</option>
 <option value=\"f\" [ad_decode $user_value "f" "selected" ""]>False</option>
</select>
"
	    } else {
		if {$edit_previous_response_p == "t"} {
		    set user_value $choice_id
		}

		append html "<select name=$element_name>
<option value=\"\">Select One</option>\n"
		db_foreach survsimp_question_choices "select choice_id, label
from survsimp_question_choices
where question_id = :question_id
order by sort_order" {
		
		    if { $user_value == $choice_id } {
			append html "<option value=$choice_id selected>$label</option>\n"
		    } else {
			append html "<option value=$choice_id>$label</option>\n"
		    }
		}
		append html "</select>"
	    }
	}
    
	"radio" {
	    if { $abstract_data_type == "boolean" } {
		if {$edit_previous_response_p == "t"} {
		    set user_value $boolean_answer
		}

		set choices [list "<input type=radio name=$element_name value=t [ad_decode $user_value "t" "checked" ""]> True" \
				 "<input type=radio name=$element_name value=f [ad_decode $user_value "f" "checked" ""]> False"]
	    } else {
		if {$edit_previous_response_p == "t"} {
		    set user_value $choice_id
		}
		
		set choices [list]
		db_foreach sursimp_question_choices_2 "select choice_id, label
from survsimp_question_choices
where question_id = :question_id
order by sort_order" {
		    if { $user_value == $choice_id } {
			lappend choices "<input type=radio name=$element_name value=$choice_id checked> $label"
		    } else {
			lappend choices "<input type=radio name=$element_name value=$choice_id> $label"
		    }
		}
	    }  
	    if { $presentation_alignment == "beside" } {
		append html [join $choices " "]
	    } else {
		append html "<blockquote>\n[join $choices "<br>\n"]\n</blockquote>"
	    }
	}

	"checkbox" {
	    set choices [list]
	    db_foreach sursimp_question_choices_3 "select * from survsimp_question_choices
where question_id = :question_id
order by sort_order" {

		if { [info exists selected_choices($choice_id)] } {
		    lappend choices "<input type=checkbox name=$element_name value=$choice_id checked> $label"
		} else {
		    lappend choices "<input type=checkbox name=$element_name value=$choice_id> $label"
		}
	    }
	    if { $presentation_alignment == "beside" } {
		append html [join $choices " "]
	    } else {
		append html "<blockquote>\n[join $choices "<br>\n"]\n</blockquote>"
	    }
	}
    }
    return $html
}

proc_doc survsimp_answer_summary_display {response_id {html_p 1} {category_id_list ""}} "Returns a string with the questions and answers. If html_p =t, the format will be html. Otherwise, it will be text.  If a list of category_ids is provided, the questions will be limited to that set of categories." {

    set return_string ""
    set question_id_previous ""

    if [empty_string_p $category_id_list] {
	set summary_query "
select
  sq.question_id,
  sq.survey_id,
  sq.sort_key,
  sq.question_text,
  sq.abstract_data_type,
  sq.required_p,
  sq.active_p,
  sq.presentation_type,
  sq.presentation_options,
  sq.presentation_alignment,
  sq.creation_user,
  sq.creation_date,
  sqr.response_id,
  sqr.question_id,
  sqr.choice_id,
  sqr.boolean_answer,
  sqr.clob_answer,
  sqr.number_answer,
  sqr.varchar_answer,
  sqr.date_answer,
  sqr.attachment_file_name
from
  survsimp_questions sq,
  survsimp_question_responses sqr
where
  sqr.response_id = :response_id
  and sq.question_id = sqr.question_id
  and sq.active_p = 't'
order by sort_key"
    } else {
	set bind_var_list [list]
	set i 0
	foreach cat_id $category_id_list {
	    incr i
	    set category_id_$i $cat_id
	    lappend bind_var_list ":category_id_$i"
	}
	set summary_query "
select
  sq.question_id,
  sq.survey_id,
  sq.sort_key,
  sq.question_text,
  sq.abstract_data_type,
  sq.required_p,
  sq.active_p,
  sq.presentation_type,
  sq.presentation_options,
  sq.presentation_alignment,
  sq.creation_user,
  sq.creation_date,
  sqr.response_id,
  sqr.choice_id,
  sqr.boolean_answer,
  sqr.clob_answer,
  sqr.number_answer,
  sqr.varchar_answer,
  sqr.date_answer,
  sqr.attachment_file_name
from
  survsimp_questions sq,
  survsimp_question_responses sqr,
  site_wide_category_map
where sqr.response_id = :response_id
  and sq.question_id = sqr.question_id
  and sq.active_p = 't'
  and site_wide_category_map.on_which_table='survsimp_questions'
  and site_wide_category_map.on_what_id = sq.question_id
  and site_wide_category_map.category_id in ([join $bind_var_list ", "])
order by sort_key"
    }
    
    db_foreach survsimp_response_display $summary_query {

	if {$question_id == $question_id_previous} {
	    continue
	}
	
	if $html_p {
	    append return_string "<b>$question_text</b> 
	<blockquote>"
	} else {
	    append return_string "$question_text:  "
	}
	append return_string [util_show_plain_text "$clob_answer $number_answer $varchar_answer $date_answer"]
	
	if {![empty_string_p $attachment_file_name]} {
	    append return_string "Uploaded file: <a href=/survsimp/view-attachment?[export_url_vars response_id question_id]>\"$attachment_file_name\"</a>"
	}
	
	if {$choice_id != 0 && ![empty_string_p $choice_id] && $question_id != $question_id_previous} {
	    set label_list [db_list survsimp_label_list "select label
	    from survsimp_question_choices, survsimp_question_responses
	    where survsimp_question_responses.question_id = :question_id
	    and survsimp_question_responses.response_id = :response_id
	    and survsimp_question_choices.choice_id = survsimp_question_responses.choice_id" ]
	    append return_string "[join $label_list ", "]"
	}
	
	if ![empty_string_p $boolean_answer] {
	    append return_string "[ad_decode $boolean_answer "t" "True" "False"]"
	    
	}
	
	if $html_p {
	    append return_string "</blockquote>
	    <P>"
	} else {
	    append return_string "\n\n"
	}
	
	set question_id_previous $question_id 
    }
    
    return "$return_string"
}

proc_doc survsimp_survey_admin_check { user_id survey_id } { Returns 1 if user is allowed to administer a survey or is a site administrator, 0 otherwise. } {
    if { ![ad_administrator_p $user_id] && [db_string survsimp_creator_p "
    select creation_user
    from   survsimp_surveys
    where  survey_id = :survey_id" ] != $user_id } {
	ad_return_error "Permission Denied" "You do not have permission to administer this survey."
	ad_script_abort
    }
}

# For site administrator new stuff page.
proc_doc ad_survsimp_new_stuff { since_when only_from_new_users_p purpose } "Produces a report of the new surveys created for the site administrator." {
    if { $purpose != "site_admin" } {
	return ""
    }
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    
    set new_survey_items ""
    
    db_for_each survsimp_responses_new "select survey_id, name, description, u.user_id, first_names || ' ' || last_name as creator_name, creation_date
from survsimp_surveys s, $users_table u
where s.creation_user = u.user_id
and creation_date> :since_when
order by creation_date desc" {
	append new_survey_items "<li><a href=\"/survsimp/admin/one?[export_url_vars survey_id]\">$name</a> ($description) created by <a href=\"/shared/community-member?[export_url_vars user_id]\">$creator_name</a> on $creation_date\n" 
    }
    
    if { ![empty_string_p $new_survey_items] } {
	return "<ul>\n\n$new_survey_items\n</ul>\n"
    } else {
	return ""
    }
}

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list "Surveys" 0] == -1 } {
    lappend ad_new_stuff_module_list [list "Surveys" ad_survsimp_new_stuff]
}

proc_doc survsimp_survey_short_name_to_id  {short_name} "Returns the id of the survey
given the short name" {
        
    set survey_id [db_string survsimp_id_from_shortname "select survey_id from survsimp_surveys where lower(short_name) = lower(:short_name)" -default ""]   
    
    return $survey_id
}

