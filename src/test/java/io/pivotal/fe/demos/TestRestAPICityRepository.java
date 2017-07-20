package io.pivotal.fe.demos;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import java.util.LinkedHashMap;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.embedded.EmbeddedWebApplicationContext;
import org.springframework.boot.context.embedded.LocalServerPort;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.web.client.RestTemplate;

/**
 * Test inspired by:
 * http://www.jayway.com/2014/07/04/integration-testing-a-spring-boot-
 * application/
 * https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-
 * testing.html
 * 
 * @author skazi
 */
@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
//@SpringApplicationConfiguration(classes = SBootCitiesServiceApplication.class)
//@WebAppConfiguration
//@WebIntegrationTest(randomPort = true)
public class TestRestAPICityRepository {
    @Autowired
    private EmbeddedWebApplicationContext server;

	@Autowired
	private TestRestTemplate restTemplate;

    @LocalServerPort
	int port;

	private String url;
	
	@Before
	public void setup() {
		url = "http://localhost:" + port + "/cities";
	}
	
	@Test
	public void canFetchCities() {
		Object apiResponse = restTemplate.getForEntity(url,Object.class);
		assertNotNull(apiResponse);
	}
	
	@Test
	public void canFetchCitiesPaged() {
		Object apiResponse = restTemplate.getForEntity(url + "?page=0&size=2",Object.class);
		assertNotNull(apiResponse);
	}

	@SuppressWarnings("unchecked")
	@Test
	public void canFetchBirmingham() {
		ResponseEntity<Object> apiResponse = restTemplate.getForEntity(url + "/search/name?q=Birmingham",Object.class);
		assertNotNull(apiResponse);
		assertNotNull(apiResponse.getBody());
		assertTrue(getTotalElements((LinkedHashMap<String, Object>) apiResponse.getBody()) == 1);
		
		apiResponse = restTemplate.getForEntity(url + "/search/name?q=Birmingham2",Object.class);
		assertNotNull(apiResponse);
		assertNotNull(apiResponse.getBody());
		assertTrue(getTotalElements((LinkedHashMap<String, Object>) apiResponse.getBody()) == 0);
	}
	
	private int getTotalElements(LinkedHashMap<String, Object> respEntity) {
		@SuppressWarnings("unchecked")
		LinkedHashMap<String, Integer> page = (LinkedHashMap<String, Integer>) respEntity.get("page");
		return page.get("totalElements").intValue();
	}
}
