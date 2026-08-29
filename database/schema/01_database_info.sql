SELECT
    DB_NAME() AS DatabaseName,
    SUSER_SNAME() AS LoginName,
    USER_NAME() AS DatabaseUser,
    @@SERVERNAME AS ServerName;