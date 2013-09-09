# /www/survsimp/admin/description-edit-2.tcl
ad_page_contract {
    Updates database with the new description
    information and return user to the main survey page.

    @param survey_id       survey which description we're updating
    @param desc_html       is the description html or plain text
    @param description     text of survey description
    @param checked_p       confirmation flag

    @author jsc@arsdigita.com
    @date   February 16, 2000
    @cvs-id description-edit-2.tcl,v 1.5.2.10 2000/09/22 01:39:20 kevin Exp
} {
    survey_id:integer
    desc_html:notnull
    description:html
    {checked_p "f"}
}

set exception_count 0
set exception_text ""

if { [empty_string_p $description] } {
    incr exception_count
    append exception_text "<li>You didn't enter a description for this survey.\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

if {$checked_p == "f"} {
    set whole_page "[ad_header "Confirm Description"]
    
    <h2>Confirm Description</h2>
    
    [ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] [list "one.tcl?[export_url_vars survey_id]" "Administer Survey"] "Confirm Description"]

    <hr>
    
    Here is how your survey description will appear:
    <blockquote><p>"

    switch $desc_html {
	"t" {
	    append whole_page "$description"
	}
	
	"pre" {
	    regsub "\[ \012\015\]+\$" $description {} description
	    set description "<pre>[ns_quotehtml $description]</pre>"
	    append whole_page "$description"
	    set desc_html  "t"
	}

	default {
	    append whole_page "[util_convert_plaintext_to_html $description]"
	}
    }

    append whole_page "<form method=post action=\"[ns_conn url]\">
    [export_form_vars description desc_html survey_id]
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
} else {
 

    db_dml survsimp_update_description "update survsimp_surveys 
      set description = :description,
          description_html_p = :desc_html
          where survey_id = :survey_id"

    db_release_unused_handles
    ad_returnredirect "one?[export_url_vars survey_id]"
}


