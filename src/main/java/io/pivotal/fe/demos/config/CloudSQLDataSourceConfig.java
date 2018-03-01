package io.pivotal.fe.demos.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.datasource.SimpleDriverDataSource;

import javax.sql.DataSource;
import java.sql.DriverManager;

@Configuration
@ConfigurationProperties(prefix="spring.datasource")
@Profile("gcp")
public class CloudSQLDataSourceConfig {
    @Value("${DATABASE_INSTANCE_CONNECTION}")
    private String instanceConnectionName;
    @Value("${MYSQL_DATABASE}")
    private String dbName;
    @Value("${MYSQL_USER}")
    private String username;
    @Value("${MYSQL_PASSWORD}")
    private String password;

	public CloudSQLDataSourceConfig() {
		super();
	}

	@Bean
	public DataSource dataSource() {
		SimpleDriverDataSource dataSource = null;
		try {
			dataSource = new SimpleDriverDataSource();
                        String jdbcUrl = String.format("jdbc:mysql://google/%s?cloudSqlInstance=%s&"
                             + "socketFactory=com.google.cloud.sql.mysql.SocketFactory",
                           dbName,
                           instanceConnectionName);
                        dataSource.setDriver(DriverManager.getDriver(jdbcUrl.toString()));
			dataSource.setUrl(jdbcUrl.toString());
			dataSource.setUsername(this.username);
			dataSource.setPassword(this.password);
		} catch (Exception e) {
			throw new IllegalStateException("An Exception occurred initialising datasource", e);
		}

		return dataSource;
	}

        public String getInstanceConnectionName() {
              return this.instanceConnectionName;
        }

        public void setInstanceConnectionName(String instanceConnectionName) {
               this.instanceConnectionName = instanceConnectionName;
        }

        public String getDbName() {
               return this.dbName;
        }

        public void setDbName(String dbName) {
               this.dbName = dbName;
        }

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}
}
