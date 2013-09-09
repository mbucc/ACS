<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id form-builder.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<p>To avoid the rather tedious chore of creating a form specification
from scratch for each form, the publishing system includes a 
form builder tool that allows to create an initial draft of the 
specification using a series of admin pages.  The specification is
then written to the file system and may be edited as desired.</p>

<p>In most situations, whenever you create a form to add something to
the database, you also need to create one to allow updates to the
information at a later time.  Sometimes you also need a form to delete 
the information as well.  The best place to start is with the add
form.</p>

<ol>

<li>Go to the first page of the form builder at
<tt>/admin/template/form-builder.adp</tt>.  If you are reading the
tutorial on the distribution site, you can try it <a
href="../../admin/form-builder.adp" target=Resource>here</a>.  Your
finished spec will be output to your browser rather than to the file
system.

<li>Complete the general properties of the form and give a URL for
the location of the finished specification.  Choose the tables
that will be modified by submission of the form.

<li>On submission of this form the system directs you to a page for
building elements into the form.  Note that this page uses a large
amount of JavaScript and is probably unreliable on anything but the
latest Netscape and Microsoft browsers.  If it doesn't work for you,
you can always fall back to writing the files from scratch in your
text editor.

<li>To add an element to the form, it is easiest to begin by mapping
it to a column in a database table:

<ol>

<li>Choose a table from the list of tables.  The columns in that table
should appear in the columns list.

<li>Choose a column from the list of columns.

<li>Choose a key type.  For insert forms, the terms parent and child
are synonomous with primary and foreign keys, respectively.  This is
important for ensuring that inserts occur in the proper order to avoid
child constraint violations.  For update and delete forms, a key
designation in this context simply means that the where clause
restricting the scope of the operation should include the form
value(s) that map to that particular column.

<li>Click the Add link to add this column to the database map for the
element you are building.  By default, the column name is filled in as
the name of the element.

<li>You can map the element to any number of columns.  For example,
for a complex registration form it might be necessary to map the
<tt>user_id</tt> form element into several different tables.  For the
primary users table, you would map it as a parent key, and for 
subsidiary tables you would map it as a child key.

</ol>

<p>Once you have specified the database column(s) to which the element
maps, complete the other element properties:

<ol>

<li>The status property indicates whether the user must enter
a value for a form element (i.e. whether a null value is acceptable).

<li>The label property is the plain english tag attached to the
form widget on the automatically generated form.

<li>The widget property is type of widget to place on the form.  Some
widgets, such as date, are compounded from a set of basic widgets.
The form manager handles the transformation from this set of widgets
into a single value in the appropriate format.

<li>The data type property is used for validating of the form input
upon submission.

<li>The defaults property may be used to specify default values for the
form element.  For widgets where multiple selections are possible
(multiple select lists and check box groups), the query result should
be a single column, the eval should return a list, and the static
string should be comma-delimited string values.  For all other widgets
the condition should produce a single value.

<li>The options property may be used to specify options for 
select lists and radio or checkbox groups.  The query result should be
two columns in the form (label, value), the eval should return a list
of duplets (i.e. { { label value } { label value } ... }), and the
static string should be in the form label=value,label=value,....

</ol>

<p>Once you have completed specifying the element properties, click the
Add link to add it to the list of elements.  Repeat this for each
element you wish to add to the form.</p>

<li>When you have added all the required elements to the form, click
the Submit button below the list of form elements to write the
form specification to the file system.</p>

</ol>

