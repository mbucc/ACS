<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id forms.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Form Manager
</h2>

part of the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<div align=right>
<a href="tags/index">Previous</a> |
<a href="index">Top</a>
</div>

<h3>Overview</h3>

<p>Community and service-oriented web sites collect a large amount
of information from their members.  At each location where information
is collected, the development team has to follow a fairly routine process:</p>
<ul>

<li>Create a form to allow new user input.  Some input options, such
as the user's state of residence or the breed of their dog, have to be
pulled from database tables.

<li>Write code to validate user submissions and insert them into the
database.

<li>Create a form to allow users to edit previously submitted
information.  Default values of input fields must be set to the user's
previous submissions to avoid reentry of unchanged information.

<li>Wire the forms(s) into a design template provided by the publisher.

</ul>

<p>To ensure consistency and speed site development, the form manager
allows developers to circumvent the need to write custom code and HTML
for handling form generation and submission in most situations.  All
input elements on a form are generated from a structured specification
file (analogous to the template specification file) stored in the file
system.  The specification file includes all information necessary for
generating and handling each form element:</p>

<ul>
<li>The type of database action to perform (i.e. insert, update, delete, 
nothing).
<li>Other actions to perform either before or after the database
action (i.e. setting cookies, sending messages)
<li>The type of form element (i.e. a text box, radio buttons, 
dropdown menu, etc.)
<li>For edit forms, the source of the data to use as a default value.
<li>Which options to offer in that form element (i.e. male or female,
or a list of states, or a list of dog breeds)
<li>The type of data expected (i.e. whether a number or text
string is expected as input to a text box).
<li>How and where the input to this form element is stored in the database.
</ul>

<p>The specification is flexible enough to allow a single form
submission to act on any number of database tables.  Because the form
manager is built on the template system, the HTML code for the forms
may either be generated automatically by a master form template, or
may be stored on an individual basis and customized by a template
author without the intervention of the developer.  Designers are free
to organize and embellish the form in any way they choose, provided
they understand the use of a few simple custom markup tags, as used
by the template system.</p>

<h3>The Form Specification</h3>

<p>To implement a form using the form manager, the developer must
first write a <a href="formspec">form specification</a>, which are
stored in the server page tree as plain text files with the
<tt>.form</tt> extension.  Like the template specification files, the
form specifications are XML documents.

<h3>The Form Template</h3>

<p>The form manager defines a custom markup tag, <tt>formtemplate</tt>,
to embed a form in a template.  This tag substitutes for the normal
<tt>form</tt> declaration used in static HTML.  It expects
a single attribute, <tt>SRC</tt>, specifying a relative or
absolute URL to the relevant form specification.  When this tag
is encountered in a a template, the form manager takes the
following actions:</p>

<ul>
<li>Retrieve the form specification from a special cache.  If the
cache does not contain the specification, the specification file
is loaded and parsed first.
<li>Output the HTML code for the <tt>FORM</tt> tag to the connection.
<li>Generate the HTML necessary to render each element in the 
form.  This may involve some or all of the following steps:

<ul>
<li>Perform a database query or evaluate Tcl code to generate a list
of options (for SELECT, CHECKBOX and RADIO elements).
<li>Perform a database query or evaluate Tcl code to generate default
value(s) for the element (all element types).
<li>Generate the HTML necessary to render the actual widget in the
form.  Note that is HTML is devoid of formatting and consists solely
of an <tt>INPUT</tt> tag or a <tt>SELECT</tt> block.
<li>Set a global variable with the resulting HTML that can be
referenced by the template author.
</ul>

<li>Parse the template within the <tt>formtemplate</tt> container
and output to the connection.  One of two scenarios is possible here:

<ul>
<li>If the <tt>formtemplate</tt> container is empty (nothing but white
space) then the form is generated automatically according to the
a master form template stored at <tt>/templates/forms/master</tt>.
<li>If the container is not empty, it is assumed to be a customized
template and is parsed accordingly.  Within the template, the template
author may embed the HTML for the form elements using 
 the <tt>formwidget</tt> tag.  This tag expects a single attribute,
<tt>NAME</tt>, giving the name of the element as per the form
specification.  This attribute may either use the fully qualified
name of the form element, <tt><em>form_name.form_element_name</em></tt>,
or simply use the form element name as shorthand  (Naming conflicts
are actually unlikely in the case of forms so shorthand is probably
always OK).
Template authors have the option to use the 
<tt>FORMLABEL</tt> tag to embed a label for each element, or
substitute their own text.
</ul>

<li>Output the closing <tt>FORM</tt> tag.

</ul>

<h3>Form Processing</h3>

<p>Once a form is submitted, the form manager handles all routine
processing steps, including:</p>

<ul>

<li>Preprocessing steps consisting of arbitrary code that the
developer wants to perform prior to the database actions.

<li>Validation according to the data type specified in the form
specification.  The ability to add custom datatypes is supported.

<li>Transformation of submitted values according to data type.  This
may involve consolidation of values into a single value, as is the
case for data values, or any sort of parsing or substitution that
may be required (for example, removing spaces and dashes from a phone
number or social security number).  Validation and transformation
are performed by the same set of procedures, since the code to
perform each of these functions tends to overlap.

<li>Preparation of any number of insert, update or delete database
statements based on the element-to-table and column mappings given
in the form specification.  Each form element may be mapped into
any number of tables.  (For example, for a complex registration
form that asks for address and demographics, the <tt>user_id</tt> 
element might map into at least three different tables).  Elements
that map into primary key columns are acted on first for inserts
and last for deletes to avoid
referential integrity problems.  The ability to perform multiple
inserts or updates based on a multiple select element or set
of checkboxes is also supported.

<li>Execution of the database statements.  Typical errors, such
as unique constraint violations are handled in a standard way,
avoiding the need for custom code for every form handler.

<li>Postprocessing consisting of arbitrary code that the
developer wants to perform following the database actions.

</ul>

<div align=right>
<a href="tags/index">Previous</a> |
<a href="index">Top</a>
</div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>





