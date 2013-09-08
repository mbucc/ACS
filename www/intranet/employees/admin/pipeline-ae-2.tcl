# /www/intranet/employees/admin/pipeline-ae-2.tcl

ad_page_contract {
    manage the employee pipeline 
    @author teadams@arsdigita.com
    @creation-date April 26, 2000
    @cvs-id pipeline-ae-2.tcl,v 3.6.2.11 2000/08/23 00:32:15 mbryzek Exp
    @param      state_id          The state id
    @param      office_id         The office id
    @param      team_id           The team id
    @param      experience_id     The experience id
    @param      source_id         The source id
    @param      job_id            The job id
    @param      projected_start_date  The projected start date
    @param      user_id           The user id of the employee
    @param      pipeline_note     A note
    @param      probability_to_start Likelihood of starting
    @param      job_listing_id    Job listing id
    @param      return_url        Optional The url return to
} {
    state_id:naturalnum
    office_id:naturalnum
    team_id:naturalnum
    experience_id:naturalnum
    source_id:naturalnum
    job_id:naturalnum
    projected_start_date:array,date
    user_id:naturalnum
    pipeline_note
    probability_to_start:naturalnum
    job_listing_id:naturalnum
    return_url:optional
}


set projected_start_date_date $projected_start_date(date)


set exists_p [db_string get_exists_p "select count(user_id) 
from im_employee_pipeline
where user_id = :user_id"]

if {$exists_p} {
    db_dml update_pipeline "update im_employee_pipeline 
    set state_id = :state_id, 
    office_id = :office_id, 
    team_id = :team_id, 
    experience_id = :experience_id,
    source_id = :source_id, 
    job_id = :job_id, 
    note = :pipeline_note,
    probability_to_start = :probability_to_start,
    projected_start_date = :projected_start_date_date,
    job_listing_id = :job_listing_id
    where user_id = :user_id"
} else {
    db_dml insert_into_pipeline "insert into im_employee_pipeline
    (state_id, office_id, team_id, experience_id, source_id, job_id, projected_start_date, note, probability_to_start,job_listing_id,user_id) 
    values (:state_id, :office_id, :team_id, :experience_id, :source_id, :job_id, :projected_start_date_date, :pipeline_note, :probability_to_start, 
    :job_listing_id, :user_id)"
}

if [info exist return_url] {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "pipeline-ae?[export_url_vars user_id]"
}

## END FILE pipeline-ae-2.tcl

