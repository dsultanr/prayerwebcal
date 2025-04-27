package praytimes;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import javax.json.Json;
import javax.json.JsonObject;

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
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String timeZoneId = "America/New_York"; // Значение по умолчанию
        double lat = NumberUtils.toDouble(request.getParameter("x"), 0.0);
        double lon = NumberUtils.toDouble(request.getParameter("y"), 0.0);

        if (lat == 0.0 || lon == 0.0) {
            response.getWriter().write("{\"error\": \"Invalid coordinates\"}");
            return;
        }

        String apiUrl = "https://maps.googleapis.com/maps/api/timezone/json"
                      + "?location=" + lat + "," + lon
                      + "&timestamp=" + System.currentTimeMillis() / 1000L
                      + "&key=AIzaSyAqdQs__cSP8PvVmOygcflxZs5Pd1xfmEA";

        try {
            HttpURLConnection connection = (HttpURLConnection) new URL(apiUrl).openConnection();
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept", "application/json");

            if (connection.getResponseCode() == 200) { // Проверяем успешный статус
                try (InputStream responseStream = connection.getInputStream()) {
                    JsonObject json = Json.createReader(responseStream).readObject();
                    timeZoneId = json.getString("timeZoneId", timeZoneId);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.getWriter().write("{\"timeZoneId\": \"" + timeZoneId + "\"}");
    }
}
