/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package praytimes;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Set;
import java.util.TreeSet;
import org.apache.commons.lang3.StringUtils;

/**
 *
 * @author user
 */
public class cities
{

    public static Set<City> get_cities() throws FileNotFoundException, IOException {
        Set<City> cities = new TreeSet<City>();
        URL url = cities.class.getResource("cities.txt");
        File file = new File(url.getPath());
//        getClass().getClassLoader().getResourceAsStream("titles.txt");
        BufferedReader in = new BufferedReader(new InputStreamReader(new FileInputStream(file), "UTF8"));
        while (in.ready()) {
            City city = new City(in.readLine());
            cities.add(city);
        }
                
        in.close();
        return cities;
    }
    public static Set<City> get_cities(String country, String region) throws FileNotFoundException, IOException {
        Set<City> cities = new TreeSet<City>();
        URL url = cities.class.getResource("cities.txt");
        File file = new File(url.getPath());
//        getClass().getClassLoader().getResourceAsStream("titles.txt");
        BufferedReader in = new BufferedReader(new InputStreamReader(new FileInputStream(file), "UTF8"));
        while (in.ready()) {
            City city = new City(in.readLine());
            if (city.country != null && city.country.equalsIgnoreCase(country)) {
                if (region.equals("") || (city.region != null && city.region.equalsIgnoreCase(region))) {
                    cities.add(city);
                }
            }
        }
                
        in.close();
        return cities;
    }
    public static class City implements Comparable<City> {

            public String name;
            public String region;
            public String countryCode;
            public String country;
            public Double latitude;
            public Double longitude;
            public String timeZone;
            public String location;
            public String url;

            public City(String cityRecord) {
                    String[] city = cityRecord.split("#");
                    name = city[0].trim();
                    region = city[1].trim();
                    countryCode = city[2].trim();
                    country = city[3].trim();
                    latitude = Math.round(Float.parseFloat(city[4]) * 100.) / 100.;
                    longitude = Math.round(Float.parseFloat(city[5]) * 100.) / 100.;
                    timeZone = city[6];
                    location = "" + name;
                    if (StringUtils.isBlank(region) || region.matches("[0-9]"))
                            location += ", " + country;
                    else
                            location += ", " + region + ", " + country;
                    url = "/loc/" + Config.clean(location) + "/x=" + latitude + ":y=" + longitude + ":tz=" + URLEncoder.encode(timeZone);
            }

            @Override
            public boolean equals(Object other) {
                    City otherCity = (City) other;
                    return name.toLowerCase().equals(otherCity.name.toLowerCase()) && Math.round(latitude) == Math.round(otherCity.latitude)
                                    && Math.round(longitude) == Math.round(otherCity.longitude);
            }

            @Override
            public int compareTo(City otherCity) {
                    if (equals(otherCity))
                            return 0;
                    int c = country.compareTo(otherCity.country);
                    if (c == 0)
                            c = region.compareTo(otherCity.region);
                    if (c == 0)
                            c = ((Double) (latitude - longitude)).compareTo(((Double) (otherCity.latitude - otherCity.longitude)));
                    return c;
            }

    }
}
