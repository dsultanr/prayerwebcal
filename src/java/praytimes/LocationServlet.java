package praytimes;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang3.StringUtils;

public class LocationServlet extends HttpServlet {

	private static final long serialVersionUID = -1;

	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String l = null;
                String request_location = "";
		if (request.getServletPath().contains(".html")) {
			l = StringUtils.replace(request.getServletPath().substring(1), ".html", "");
			l = StringUtils.defaultIfBlank(l, "Unknown");
			response.sendRedirect("/loc/" + l + "?" + StringUtils.defaultIfBlank(request.getQueryString(), ""));
		} else if (request.getServletPath().equals("/loc")) {
			try {
                                Pattern pattern = Pattern.compile("/(.*?)/.*");
                                Matcher matcher = pattern.matcher(request.getPathInfo());                
                                if (matcher.find()) {
                                    request_location = matcher.group(1);
                                }
                                request.setAttribute("cfg", new Config(request));
				request.getRequestDispatcher("/index.jsp").forward(request, response);
			} catch (Exception e) {
                            if (!request_location.equals("")) {
                                response.setStatus(HttpServletResponse.SC_MOVED_PERMANENTLY);
                                response.setHeader("Location", "/search.jsp?query=" + request_location);
                                return;
                            }
                            throw new ServletException(e);
			}
		}
	}

}
