package praytimes;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import javax.json.Json;
import javax.json.JsonObject;
import javax.json.JsonReader;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.lang.math.NumberUtils;

@WebServlet("/timezone")
public class Timezone extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        String timeZoneId = "America/New_York"; // default

        double lat = NumberUtils.toDouble(request.getParameter("x"), 0.0);
        double lon = NumberUtils.toDouble(request.getParameter("y"), 0.0);

        if (lat == 0.0 || lon == 0.0) {
            response.getWriter().write("{\"error\":\"Invalid coordinates\"}");
            return;
        }

        String username = "dsultanr"; // TODO: Указать свой username на GeoNames.org
        String apiUrl = String.format("http://api.geonames.org/timezoneJSON?lat=%f&lng=%f&username=%s", lat, lon, username);

        try {
            URL url = new URL(apiUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(3000);
            conn.setReadTimeout(3000);

            if (conn.getResponseCode() == 200) {
                try (InputStream in = conn.getInputStream();
                    JsonReader reader = Json.createReader(in)) {
                    JsonObject json = reader.readObject();
                    timeZoneId = json.getString("timezoneId", timeZoneId);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.getWriter().write("{\"timeZoneId\":\"" + timeZoneId + "\"}");
    }
}
