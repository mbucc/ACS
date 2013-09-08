ad_page_contract {
    This is file /www/doc/schema-browser/trigger.tcl

    @param trigger_name

    @author ?
    @creation-date ?
    @cvs-id trigger.tcl,v 1.4.2.5 2000/09/22 01:37:25 kevin Exp

} {
    trigger_name:notnull
}


set html "[ad_header "[ad_system_name]  One trigger "]

<h2>[ad_system_name] Schema Browser</h2>
[ad_context_bar_ws [list index.tcl "Schema Browser"] "One Trigger"]
"


db_1row unused "
    select
        table_name,
        trigger_type,
        triggering_event,
        status,
        trigger_body
    from
        user_triggers
    where
        trigger_name = upper(:trigger_name)"

regsub -all ";" $trigger_body ";<br> " trigger_body
regsub "begin" $trigger_body "begin<br>" trigger_body

append html "
<hr>
create or replace trigger [string tolower $trigger_name]
$triggering_event $trigger_type
<br>
[util_convert_plaintext_to_html $trigger_body]

[ad_footer]
"



doc_return  200 text/html $html