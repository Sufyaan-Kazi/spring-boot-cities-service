package com.google.ce.demos.controller;

import com.google.ce.demos.domain.City;
import com.google.ce.demos.repositories.CityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Class to add optional non-HATEOS and non-pageable list of all cities
 * @author skazi
 *
 */
@RestController
public class WebController {
	@Autowired
	private CityRepository repo;

	@RequestMapping("/cities_all")
	public Iterable<City> showAllCities() {
		return repo.findAll();
	}
}
