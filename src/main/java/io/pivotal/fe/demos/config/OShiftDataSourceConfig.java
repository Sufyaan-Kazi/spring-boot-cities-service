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
//@ConfigurationProperties(prefix="spring.datasource")
@Profile("oshift")
public class OShiftDataSourceConfig {

    //private String driverClassName;
    private String port="3306";
    @Value("${DATABASE_SERVICE_NAME}")
    private String host;
    @Value("${MYSQL_DATABASE}")
    private String dbName;
    @Value("${MYSQL_USER}")
    private String username;
    @Value("${MYSQL_PASSWORD}")
    private String password;

    public OShiftDataSourceConfig() {
        super();
    }

    @Bean
    public DataSource dataSource() {
        SimpleDriverDataSource dataSource = null;
        try {
            //Class.forName(this.driverClassName);
            dataSource = new SimpleDriverDataSource();
            StringBuilder url = new StringBuilder("jdbc:mysql://");
            url.append(host).append(":").append(port).append("/").append(dbName).append("?autoReconnect=true&useSSL=false");
            dataSource.setDriver(DriverManager.getDriver(url.toString()));
            dataSource.setUrl(url.toString());
            dataSource.setUsername(this.username);
            dataSource.setPassword(this.password);
        } catch (Exception e) {
            throw new IllegalStateException("An Exception occurred initialising datasource", e);
        }

        return dataSource;
    }

    public String getPort() {
        return port;
    }

    public void setPort(String port) {
        this.port = port;
    }

    public String getDbName() {
        return dbName;
    }

    public void setDbName(String dbName) {
        this.dbName = dbName;
    }

    public String getHost() {
        return host;
    }

    public void setHost(String host) {
        this.host = host;
    }

	public String getDriverClassName() {
		//return driverClassName;
        return "";
	}

	public void setDriverClassName(String driverClassName) {
		//this.driverClassName = driverClassName;
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
