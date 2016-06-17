agilefant {
	database {
		jndi-name = "jdbc/agilefant"

		driver-class = "com.mysql.jdbc.Driver"
		username = "{{DBUSER}}"
		password = "{{DBPASS}}"
		url = "jdbc:mysql://{{DBHOST}}/{{DBNAME}}?relaxAutoCommit=true&autoReconnect=true&useUnicode=true&characterEncoding=utf-8&autoReconnectForPools=true"
	}
	hibernate.dialect = org.hibernate.dialect.MySQL5InnoDBDialect
	hibernate.show_sql = false
	hibernate.max_fetch_depth = 1
	hibernate.default_batch_fetch_size = 64
	version = "3.5.4"
	import.enabled = true
}
