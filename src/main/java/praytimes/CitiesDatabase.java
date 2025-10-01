package praytimes;

import java.io.InputStream;
import java.net.URLEncoder;
import java.sql.*;
import java.util.*;
import java.util.Locale;
import org.apache.commons.lang3.StringUtils;

/**
 * Optimized cities database using SQLite
 * Replaces the old text file approach with efficient SQL queries
 */
public class CitiesDatabase {

    private static Connection connection = null;

    static {
        try {
            initializeDatabase();
        } catch (SQLException e) {
            throw new RuntimeException("Failed to initialize cities database", e);
        }
    }

    private static void initializeDatabase() throws SQLException {
        try {
            // Load SQLite JDBC driver
            Class.forName("org.sqlite.JDBC");

            // Get database from resources
            InputStream dbStream = CitiesDatabase.class.getResourceAsStream("/cities.db");
            if (dbStream == null) {
                throw new RuntimeException("cities.db not found in resources");
            }

            // Create read-only connection to database
            connection = DriverManager.getConnection("jdbc:sqlite::resource:cities.db?open_mode=1");

            System.out.println("Cities database initialized successfully");

        } catch (ClassNotFoundException e) {
            throw new SQLException("SQLite JDBC driver not found", e);
        }
    }

    /**
     * Get list of all countries with region information
     * Used for the main country selection page
     */
    public static List<CountryInfo> getCountries() throws SQLException {
        String sql = "SELECT name, city_count, has_regions " +
                "FROM countries " +
                "ORDER BY name";

        List<CountryInfo> countries = new ArrayList<>();

        try (PreparedStatement stmt = connection.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                String countryName = rs.getString("name");
                int cityCount = rs.getInt("city_count");
                boolean hasRegions = rs.getBoolean("has_regions");

                countries.add(new CountryInfo(countryName, hasRegions, cityCount));
            }
        }

        return countries;
    }

    /**
     * Information about a region including code and name
     */
    public static class RegionInfo {
        public final String code;
        public final String name;

        public RegionInfo(String code, String name) {
            this.code = code;
            this.name = name;
        }
    }

    /**
     * Get list of regions for a specific country with codes and names
     * Used when a country has regions/states
     */
    public static List<RegionInfo> getRegionsWithInfo(String countryName) throws SQLException {
        String sql = "SELECT r.code, COALESCE(r.name, r.code) as region_name " +
                "FROM regions r " +
                "JOIN countries c ON r.country_id = c.id " +
                "WHERE c.name = ? " +
                "ORDER BY COALESCE(r.name, r.code)";

        List<RegionInfo> regions = new ArrayList<>();

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, countryName);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    regions.add(new RegionInfo(
                        rs.getString("code"),
                        rs.getString("region_name")
                    ));
                }
            }
        }

        return regions;
    }

    /**
     * Get list of regions for a specific country (backward compatibility)
     * Used when a country has regions/states
     */
    public static List<String> getRegions(String countryName) throws SQLException {
        String sql = "SELECT COALESCE(r.name, r.code) as region_name " +
                "FROM regions r " +
                "JOIN countries c ON r.country_id = c.id " +
                "WHERE c.name = ? " +
                "ORDER BY COALESCE(r.name, r.code)";

        List<String> regions = new ArrayList<>();

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, countryName);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    regions.add(rs.getString("region_name"));
                }
            }
        }

        return regions;
    }

    /**
     * Get cities for a specific country and optional region
     * Used for the final city selection
     */
    public static Set<cities.City> getCities(String countryName, String regionName) throws SQLException {
        String sql;
        if (StringUtils.isBlank(regionName)) {
            sql = "SELECT ci.name, r.code as region_code, co.code as country_code, " +
                    "co.name as country_name, ci.latitude, ci.longitude, ci.timezone " +
                    "FROM cities ci " +
                    "JOIN countries co ON ci.country_id = co.id " +
                    "LEFT JOIN regions r ON ci.region_id = r.id " +
                    "WHERE co.name = ? " +
                    "ORDER BY ci.name";
        } else {
            sql = "SELECT ci.name, r.code as region_code, co.code as country_code, " +
                    "co.name as country_name, ci.latitude, ci.longitude, ci.timezone " +
                    "FROM cities ci " +
                    "JOIN countries co ON ci.country_id = co.id " +
                    "JOIN regions r ON ci.region_id = r.id " +
                    "WHERE co.name = ? AND r.code = ? " +
                    "ORDER BY ci.name";
        }

        Set<cities.City> citySet = new TreeSet<>();

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, countryName);
            if (!StringUtils.isBlank(regionName)) {
                stmt.setString(2, regionName);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    String regionCode = rs.getString("region_code");
                    String cityRecord = String.format(Locale.US, "%s#%s#%s#%s#%.6f#%.6f#%s",
                        rs.getString("name"),
                        regionCode != null ? regionCode : "",
                        rs.getString("country_code"),
                        rs.getString("country_name"),
                        rs.getDouble("latitude"),
                        rs.getDouble("longitude"),
                        rs.getString("timezone")
                    );

                    citySet.add(new cities.City(cityRecord));
                }
            }
        }

        return citySet;
    }

    /**
     * Get all cities (for backward compatibility)
     * WARNING: This loads 162K+ cities into memory - use only when necessary
     */
    public static Set<cities.City> getAllCities() throws SQLException {
        String sql = "SELECT ci.name, r.code as region_code, co.code as country_code, " +
                "co.name as country_name, ci.latitude, ci.longitude, ci.timezone " +
                "FROM cities ci " +
                "JOIN countries co ON ci.country_id = co.id " +
                "LEFT JOIN regions r ON ci.region_id = r.id " +
                "ORDER BY co.name, ci.name " +
                "LIMIT 50000";

        Set<cities.City> citySet = new TreeSet<>();

        try (PreparedStatement stmt = connection.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                String regionCode = rs.getString("region_code");
                String cityRecord = String.format("%s#%s#%s#%s#%f#%f#%s",
                    rs.getString("name"),
                    regionCode != null ? regionCode : "",
                    rs.getString("country_code"),
                    rs.getString("country_name"),
                    rs.getDouble("latitude"),
                    rs.getDouble("longitude"),
                    rs.getString("timezone")
                );

                citySet.add(new cities.City(cityRecord));
            }
        }

        return citySet;
    }

    /**
     * Information about a country including whether it has regions
     */
    public static class CountryInfo {
        public final String name;
        public final boolean hasRegions;
        public final int cityCount;

        public CountryInfo(String name, boolean hasRegions, int cityCount) {
            this.name = name;
            this.hasRegions = hasRegions;
            this.cityCount = cityCount;
        }

        @Override
        public String toString() {
            return String.format("%s (%d cities%s)",
                name, cityCount, hasRegions ? ", has regions" : "");
        }
    }

    /**
     * Close database connection (for cleanup)
     */
    public static void closeDatabase() {
        if (connection != null) {
            try {
                connection.close();
                connection = null;
            } catch (SQLException e) {
                System.err.println("Error closing database: " + e.getMessage());
            }
        }
    }
}