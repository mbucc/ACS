<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id datamap.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<html>
<head>
<title>
Dynamic Publishing System
</title>
</head>
<body>

<h2>
Mapping Forms to the Database
</h2>

for the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<h3>Overview</h3>

<p>In creating a generic system to handle form submissions, the
greatest intellectual and technical challenge was to figure out how to
create a functional map between form elements and their corresponding
columns in the database.  This document explains some of the specific
issues with implementing such a map.</p>

<ul> 

<li><p>Any form element should be able to map to multiple columns in
the database.  For example, imagine a registration form that asks for
e-mail, address and gender.  When the form is created, a unique user
ID is generated from a database sequence and placed in the form as a
hidden element.  When the form is submitted, that same user ID needs
to be inserted into the primary users table as well as subsidiary
tables for user contact information and demographics.</p>

<li><p>Each form element should have its own map into the database.
Alternatively stated, a form should be a collection of independently
specified form elements.  This reduces the possibility for error on
the part of the developer, and ensures the greatest possible
flexibility for reusing elements selectively across multiple forms.
For example, most types of information maintained in the database
require both <b>Add</b> and <b>Edit</b> forms.  The form elements in
the Edit form are typically a subset of those in the Add form, with
the exception of permanent data like a registration date.</p>

<li><p>The actual sequence of DML statements required to handle the form
submission must be compiled by the form manager.  This is a necessary
corollary to the previous design goal.  To determine this sequence
correctly, the code must take primary-foreign key relationships into
account.  To continue the example of the registration form, a row
must be inserted into the primary users table before corresponding
rows are inserted into the user contact and demographics tables.</p>

<li><p>Multiple values in a single form submission may require
modifications to the same column in the database.  This may occur when
separate form elements map to the same column, or when a single form
element permits multiple values to be submitted (i.e. checkbox groups
and multiple select lists).  As a result, the number and type of DML
statements required to modify a table correctly in response to a form
submission must be dynamically determined.</p>

<p>For example, the user registration may have a series of checkboxes
for the user to specify their particular subjects of interest.  The
submitted form may thus include values for any number of subject IDs.
Assuming a typical normalized data model, then each subject ID
requires a separate insert statement into a user-subject mapping
table, along with the unique user ID.</p>

<p>When the user edits their subjects of interest, the number of rows
in the user-subject mapping table may actually have to change.  An
update operation in this case may thus require a delete followed by a
series of insert statements, rather than a single update statement.
The form manager should be able to handle these situations
automatically.</p>

<li><p>It should be possible to use the value of any column to
restrict the scope of an update or delete statement, regardless of its
status as a primary or foreign key.  For example, imagine an user
administrative form that updated some information based on the users'
state of residence.  In this instance the where clause for the update
statement must contain the state code, rather than the user ID as
the actual structure of the table would suggest.
</p>

</ul>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>