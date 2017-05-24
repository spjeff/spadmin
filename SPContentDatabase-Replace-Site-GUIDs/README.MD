# Clone Content Database – SQL Copy + Generate SPSite GUID

[ from blog post at [http://www.spjeff.com/2017/05/22/clone-content-database-sql-copy-generate-spsite-guid/](http://www.spjeff.com/2017/05/22/clone-content-database-sql-copy-generate-spsite-guid/)

Tried of waiting for Backup-SPSite / Restore-SPSite?  Me too.  Why not clone the SQL content database with SQL backup and restore?  

Well, SharePoint requires every Site Collection on a given to have a unique GUID.  When we clone a SQL content database and attempt Mount-SPContentDatabase an error comes up that the GUID already exists on the local farm.  No bueno.

Why not generate and replace the GUID?   In theory, we can UDPATE the SQL database internally with fresh new GUID numbers and SharePoint would recognize as new site collections.  No conflict.  That is exactly what the PowerShell below does.  By walking the schema, finding “SiteID” and “tp_SiteID” columns, and replacing the old GUID with a new GUID.

The larger the site collection, the better this works on time savings.  SQL internally can backup and restore a database much faster than waiting for Backup-SPSite/Restore-SPSite to export/import binary data across the wire to the SharePoint front end file system.

In the example below you can see a brand new team site created with GUID “82dad5a8-aa6e-4480-a10e-16cd2597c18b” in a dedicated SQL content database, taken offline, updated with PowerShell to replace old GUID with new GUID “0f59c302-92ea-4fac-b32b-799f3dd41264” and then successfully consumed again.

* **NOTE** – You still need a unique URL, so be sure to run Mount-SPContentDatabase against a secondary web application.

* **NOTE** – This is completely unsupported.  Use at your own risk.   Worked well on Dev and Test environments for me.

## Context Diagram
![Context Diagram](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_12.png "Context Diagram")

## Screenshots
![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_3.png "img")
![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_4.png "img")
![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_5.png "img")
![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_6.png "img")


![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_7.png "img")
![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_8.png "img")
![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_9.png "img")
![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_10.png "img")

![img](http://www.spjeff.com/wp-content/ftp_uploads/2be7c940b573_98A1/image_11.png "img")