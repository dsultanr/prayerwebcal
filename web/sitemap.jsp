<%@page import="java.util.Set"%><%@page import="java.util.TreeSet"%><%@page import="praytimes.Config"%><%@page import="praytimes.cities.City"%><%@page import="praytimes.cities"%><%@page	import="org.apache.commons.lang3.StringUtils"%><%@page import="java.io.FileReader"%><%@page import="java.io.BufferedReader"%><%@page	contentType="text/plain; charset=UTF-8"%><%
    Set<City> cities = praytimes.cities.get_cities();
    for (City city : cities) { %>https://prayerwebcal.dsultan.com<%=city.url%>
<%
    }
%>