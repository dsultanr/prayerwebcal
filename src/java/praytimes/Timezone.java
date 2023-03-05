package praytimes;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import javax.json.Json;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Optional;
import java.time.ZoneId;
import java.util.stream.Collectors;
import javax.json.JsonObject;
//import net.iakovlev.timeshape.TimeZoneEngine;
import org.apache.commons.lang.math.NumberUtils;

@WebServlet("/timezone")
public class Timezone extends HttpServlet {

	private static final long serialVersionUID = -1;

	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
            StringBuilder stringBuilder = new StringBuilder();
            stringBuilder.setLength(0);
            PrintWriter out = response.getWriter();
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            String timeZoneId = "America/New_York";
            try
            {
                double lat = NumberUtils.toDouble(request.getParameter("x"));
                double lon = NumberUtils.toDouble(request.getParameter("y"));
                URL url = new URL("https://maps.googleapis.com/maps/api/timezone/json?location=" + lat +"," + lon + "&timestamp=" + System.currentTimeMillis() / 1000L + "&key=AIzaSyAqdQs__cSP8PvVmOygcflxZs5Pd1xfmEA");
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestProperty("accept", "application/json");
                InputStream responseStream = connection.getInputStream();
                JsonObject json = Json.createReader(responseStream).readObject();
                if (json != null)
                {                    
//                    System.out.println(json.toString());
                    timeZoneId = json.getString("timeZoneId");
                }
            } catch(Exception e) {
                e.printStackTrace();
            } finally {
                stringBuilder.append("{\"timeZoneId\": \"" + timeZoneId + "\"}");
                out.print(stringBuilder.toString());
            }
        }   
}
