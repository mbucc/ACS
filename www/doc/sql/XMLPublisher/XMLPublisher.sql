create or replace procedure apply_xsl (doc_id number, xsl_name varchar2) 
as language java name 'XMLPublisher.applyXSL(int, java.lang.String)';
/
show errors
commit;


