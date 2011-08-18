# 
# /tcl/survey-simple-defs.tcl
#
# by philg@mit.edu on February 9, 2000
# modified by teadams@mit.edu on February 28, 2000
# 
#

util_report_library_entry

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

    set db [ns_db gethandle subquery]
    
    if {![ad_administration_group_member $db survsimp "" $user_id]} {
	ns_db releasehandle $db
	ad_return_error "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
	
    ns_db releasehandle $db

    return filter_ok
}


proc_doc survsimp_question_display { db question_id } "Returns a string of HTML to display for a question, suitable for embedding in a form. The form variable is of the form \"response_to_question_\$question_id." {
    set element_name "response_to_question_$question_id"

    set selection [ns_db 1row $db "select * from survsimp_questions where question_id = $question_id"]
    set_variables_after_query

    set html $question_text
    if { $presentation_alignment == "below" } {
	append html "<br>"
    } else {
	append html " "
    }


    set user_value ""
    switch -- $presentation_type {
	"textbox" {
	    if { ![empty_string_p $user_value] } {
		append html $user_value
	    } else {
		append html "<input type=text name=$element_name value=\"[philg_quote_double_quotes $user_value]\" [ad_decode $presentation_options "large" "size=70" "medium" "size=40" "size=10"]>"
	    }
	}
	"textarea" {
	    append html "<textarea name=$element_name $presentation_options>$user_value</textarea>" 
	}
	"date" {
	    append html "[ad_dateentrywidget $element_name $user_value]" 
	}
	"select" {
	    if { $abstract_data_type == "boolean" } {
		append html "<select name=$element_name>
 <option value=\"\">Select One</option>
 <option value=\"t\" [ad_decode $user_value "t" "selected" ""]>True</option>
 <option value=\"f\" [ad_decode $user_value "f" "selected" ""]>False</option>
</select>
"
	    } else {
		append html "<select name=$element_name>
<option value=\"\">Select One</option>\n"
		set selection [ns_db select $db "select choice_id, label
from survsimp_question_choices
where question_id = $question_id
order by sort_order"]
		
		while { [ns_db getrow $db $selection] } {
		    set_variables_after_query
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
		set choices [list "<input type=radio name=$element_name value=t [ad_decode $user_value "t" "checked" ""]> True" \
				 "<input type=radio name=$element_name value=f [ad_decode $user_value "f" "checked" ""]> False"]
	    } else {
		set choices [list]
		set selection [ns_db select $db "select choice_id, label
from survsimp_question_choices
where question_id = $question_id
order by sort_order"]
		while { [ns_db getrow $db $selection] } {
		    set_variables_after_query
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
	    set selection [ns_db select $db "select * from survsimp_question_choices
where question_id = $question_id
order by sort_order"]
	    while { [ns_db getrow $db $selection] } {
		set_variables_after_query

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



proc_doc survsimp_answer_summary_display {db response_id {html_p 1} {category_id_list ""}} "Returns a string with the questions and answers. If html_p =t, the format will be html. Otherwise, it will be text.  If a list of category_ids is provided, the questions will be limited to that set of categories." {

    set return_string ""

    if [empty_string_p $category_id_list] {
    set selection [ns_db select $db "select * 
from survsimp_questions, survsimp_question_responses
where  survsimp_question_responses.response_id = $response_id
and survsimp_questions.question_id = survsimp_question_responses.question_id
and survsimp_questions.active_p = 't'
order by sort_key"]
    } else {
    set selection [ns_db select $db "select survsimp_questions.*, 
survsimp_question_responses.*
from survsimp_questions, survsimp_question_responses, site_wide_category_map
where survsimp_question_responses.response_id = $response_id
and survsimp_questions.question_id = survsimp_question_responses.question_id
and survsimp_questions.active_p = 't'
and site_wide_category_map.on_which_table='survsimp_questions'
and site_wide_category_map.on_what_id = survsimp_questions.question_id
and site_wide_category_map.category_id in ([join $category_id_list " , "])
order by sort_key"]
    }

    set db2 [ns_db gethandle subquery]
    set question_id_previous ""

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if {$question_id == $question_id_previous} {
	    continue
	}

	if $html_p {
	    append return_string "<b>$question_text</b> 
	    <blockquote>"
	} else {
	    append return_string "$question_text:  "
	}
	append return_string "$clob_answer $number_answer $varchar_answer $date_answer"

	if {$choice_id != 0 && ![empty_string_p $choice_id] && $question_id != $question_id_previous} {
	    set label_list [database_to_tcl_list $db2 "select label
	from survsimp_question_choices, survsimp_question_responses
where survsimp_question_responses.question_id = $question_id
and survsimp_question_responses.response_id = $response_id
and survsimp_question_choices.choice_id = survsimp_question_responses.choice_id"]
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
    ns_db releasehandle $db2
    return "$return_string"
}




proc_doc survsimp_survey_admin_check { db user_id survey_id } { Returns 1 if user is allowed to administer a survey or is a site administrator, 0 otherwise. } {
    if { ![ad_administrator_p $db $user_id] && [database_to_tcl_string $db "
    select creation_user
    from   survsimp_surveys
    where  survey_id = $survey_id"] != $user_id } {
	ad_return_error "Permission Denied" "You do not have permission to administer this survey."
	return -code return
    }
}

# For site administrator new stuff page.
proc_doc ad_survsimp_new_stuff { db since_when only_from_new_users_p purpose } "Produces a report of the new surveys created for the site administrator." {
    if { $purpose != "site_admin" } {
	return ""
    }
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    
    set new_survey_items ""
    set selection [ns_db select $db "select survey_id, name, description, u.user_id, first_names || ' ' || last_name as creator_name, creation_date
from survsimp_surveys s, $users_table u
where s.creation_user = u.user_id
  and creation_date> '$since_when'
order by creation_date desc"]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append new_survey_items "<li><a href=\"/survsimp/admin/one.tcl?[export_url_vars survey_id]\">$name</a> ($description) created by <a href=\"/shared/community-member.tcl?[export_url_vars user_id]\">$creator_name</a> on $creation_date\n"
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
    # we use the subquery pool so it is easy
    # to Memoize this function (we are not passing it an
    # arbitrary db handle)
    set db [ns_db gethandle subquery]
    set survey_id [database_to_tcl_string_or_null $db "select survey_id from
    survsimp_surveys where lower(short_name) = '[string tolower [DoubleApos $short_name]]'"]   
    ns_db releasehandle $db
    return $survey_id
}

util_report_successful_library_load
