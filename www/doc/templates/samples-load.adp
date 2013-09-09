<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id samples.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<html>
<head>
<title>
Dynamic Template System Tutorial
</title>

<link rel=stylesheet href="style.css" type="text/css">

</head>
<body>
<h1>
Template Tutorial: Load Sample Tables
</h1>
Karl Goldstein (<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>)
<hr>

<p>
<%
   
  set db [ns_db gethandle]

  if { ! [ns_table exists $db "ad_template_sample_users"] } {

    if [catch {
    set stmt "create table ad_template_sample_users (
                user_id                integer,
                first_name        varchar2(20),
                last_name        varchar2(20),
                address1        varchar2(40),
                address2        varchar2(40),
                city                varchar2(40),
                state                varchar2(2)
        )"

    ns_db dml $db $stmt

    set stmt "insert into ad_template_sample_users values 
                (81, 'Fred', 'Jones', '101 Main St.', NULL, 'Orange', 
                 'CA')"
    ns_db dml $db $stmt
                
    set stmt "insert into ad_template_sample_users values 
                (82, 'Frieda', 'Mae', 'Lexington Hospital',
                 '102 Central St.', 'Orange', 'CA')"
    ns_db dml $db $stmt

    set stmt "insert into ad_template_sample_users values 
                (83, 'Sally', 'Saxberg', 'Board of Supervisors',
                 '1933 Fruitvale St.', 'Woodstock', 'CA')"
    ns_db dml $db $stmt

    set stmt "insert into ad_template_sample_users values 
                (84, 'Yoruba', 'Diaz', 
                 '12 Magic Ave.', NULL, 'Lariot', 'WY')"
    ns_db dml $db $stmt

    ns_db releasehandle $db

    } errmsg] {

      ns_puts "Sorry but we were unable to create the sample data tables.
               The following error occurred: <pre>$errmsg</pre>"
    } else {

      ns_puts "The sample data tables were successfully created."
    }

  } else {

      ns_puts "The sample data tables already exist.  Please drop them
               first if you would like them to be recreated."
  }
%>
</p>

<a href="tutorial/">Return to the tutorial index</a>
