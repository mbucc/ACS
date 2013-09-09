<if %form.help% not nil>
  <p><var name="form.help"></p>
</if>

<multiple name="form.elements">
<if %form.elements.widget% ne "none">
  <?formvalues name="<var name="form.elements.name">">
</if>
</multiple>

<table border=0 cellpadding=2>

<multiple name="form.elements">
<if %form.elements.widget% not in hidden none>
  <tr>
    <td valign=top>

      <subif %form.elements.label% not nil>
        <var name="form.elements.label">
      </subif>

      &nbsp;

    </td>

    <td valign=top>

      <?list name="formvalues.<var name="form.elements.name">">
        <?var name="formvalues.<var name="form.elements.name">.item">
      <?/list>

    </td>

    </tr>

</if>
</multiple>

<if %form.submit% not nil>
<tr>
  <td>&nbsp;</td>
  <td>
    <br>
    <input type=submit value="<var name="form.submit">">
  </td>
</tr>
</if>

</table>












