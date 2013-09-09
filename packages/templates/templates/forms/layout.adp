<if %form.help% not nil>
  <p><var name="form.help"></p>
</if>

<multiple name="form.elements">
<if %form.elements.widget% eq "hidden">
  <?formwidget name="<var name="form.elements.name">">
</if>
</multiple>

<table border=0 cellspacing=0 cellpadding=2 width=100%>

<multiple name="form.elements">
<if %form.elements.widget% not in hidden none>

   <if %Last.line_break_after% ne "f"><tr></if>

   <if %form.elements.label_width% ne "0">

     <if %form.elements.label_width% nil>
      <td >
     </if>
     <else>
      <td width=<var name=form.elements.label_width>%>
     </else>

	<if %form.elements.status% eq required>
	  <font color="#AA0000"><b>
	</if>

	<if %form.elements.status% eq optional>
	  <font color="#000021"><b>
	</if>

	<if %form.elements.label% not nil>
	  <var name="form.elements.label">
	</if>

	<if %form.elements.help% not nil>
	 </b></font>
	 <br>
	    <em><var name="form.elements.help"></em>
	 </if>

	 &nbsp;

      </td>

    </if>

    <if %Last.line_break_after% ne "f">
       <td><table border=0 cellspacing=0 cellpadding=2 width=100%>
       <tr>
    </if>

   <if %form.elements.line_break_after% ne "f" or 
       %form.elements.element_width% nil>
    <td valign=top >
   </if>
   <else>
    <td valign=top width=<var name=form.elements.element_width>%>
   </else>

      <if %form.elements.widget% not in radio checkbox>
        <?formwidget name="<var name="form.elements.name">">
      </if>

      <if %form.elements.widget% in radio checkbox>
        <?formgroup name="<var name="form.elements.name">">
          <?formwidget name="<var name="form.elements.name">">&nbsp;<?formlabel name="<var name="form.elements.name">">
        <?/formgroup>
      </if>

      <?if %form.error.<var name="form.elements.name">% not nil>
        <br>      
        <font color="#AA0000">
        <?var name="form.error.<var name="form.elements.name">">
        </font>
      <?/if>

    </td>

   <if %form.elements.line_break_after% ne "f">
     </tr></table>
     </td></tr>
   </if>

</if>
</multiple>

</table>

<if %form.submit% not nil>
<table>
<tr>
  <td>&nbsp;</td>
  <td>
    <br>
    <input type=submit value="<var name="form.submit">">
  </td>
</tr>
</table>
</if>













