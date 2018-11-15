fm_custom_load_table.c
======================
Load data with ease from the database. Stop making custom fields that you don't need. Stop putting data into config files.
All data lives in the database. You write data driven code.

Loads a database table via a stored proc. The stored proce returns XML version of table as a CLOB.
The code walks the XML and creates C struct for each ROW node.
The struct could be chained into a linked list or placed into a hash depending on use case.

As an example, take the following XML. It lives in a table in the Oracle database.
 
		<ROWSET>
			<ROW>
				<SOURCE>EARTH</SOURCE>
				<ACTION>LEFT<ACTION>
			</ROW>
			<ROW>
				<SOURCE>MARS</SOURCE>
				<ACTION>RIGHT<ACTION>
			</ROW>
		</ROWSET>

The code reads this data using a stored proc. This avoid any need to define the fields to BRM's PCM API.
The code parse the XML into C structures. Those structure are used in other parts of the code base.

