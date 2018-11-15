procedure table2xml
(
i_name in varchar2,
xmlpayload out clob
) as
begin
select dbms_xmlgen.getxml('select * from ' || i_name) into xmlpayload from dual;
exception
when TOO_MANY_ROWS
then return;
when NO_DATA_FOUND
then return;
when others
then raise_application_error(-20011,'Unknown Exception in table2xml procedure');
end table2xml;



