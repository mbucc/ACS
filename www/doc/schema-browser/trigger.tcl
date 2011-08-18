set_the_usual_form_variables

#
# expected: trigger_name
#


ReturnHeaders

set db [ns_db gethandle]

set selection [ns_db 1row $db "
    select
        table_name,
        trigger_type,
        triggering_event,
        status,
        trigger_body
    from
        user_triggers
    where
        trigger_name = '[string toupper $trigger_name]'"
]

set_variables_after_query

regsub -all ";" $trigger_body ";<br> " trigger_body
regsub "begin" $trigger_body "begin<br>" trigger_body

ns_write "
<hr>
create or replace trigger [string tolower $trigger_name]
$triggering_event $trigger_type
<br>
[util_convert_plaintext_to_html $trigger_body]
"

ad_footer












