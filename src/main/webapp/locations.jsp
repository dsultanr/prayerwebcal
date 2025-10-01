<%@page import="org.apache.commons.lang3.StringUtils"%>
<%@page import="java.util.ArrayList"%>
<%@page import="praytimes.cities.City"%>
<%@page import="java.util.Set"%>
<%@page import="java.util.List"%>
<%@page import="praytimes.cities"%>
<%@page import="praytimes.CitiesDatabase.CountryInfo"%>
<%@page import="praytimes.CitiesDatabase.RegionInfo"%>
<%@page import="praytimes.Config"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@page
	contentType="text/html; charset=UTF-8"%>
<html>
<head>
<title>Prayer Webcal Locations - Subscribe to your Personal World Prayer Times Calendar</title>
<%@include file="tags.jsp"%>
</head>
<body>

	<main role="main" class="container">

	<div class="header row">
		<div class="d-flex w-100 justify-content-between">
			<div class="header__title">
				<h1>Prayer Webcal</h1>
				<h4>World Cities and Time Zones</h4>
			</div>
			<div class="header__settings">
				<div class="header__settings__icon pt-1">
					<a class="fas fa-times-circle d-inline" href="/"></a>
				</div>
			</div>
		</div>
	</div>

	<div class="pl-3 pr-3 mt-3">
		<div class="list-group city-list">
		<!-- <input type="search" class="pl-1 pr-1 form-control city-search" placeholder="Search city..." /> -->
		<%
                        String country = StringUtils.defaultString(request.getParameter("country"));
                        String region = StringUtils.defaultString(request.getParameter("region"));
                        String has_regions = StringUtils.defaultString(request.getParameter("has_regions"));
                        if (country.equals("")) {
                            try {
                                List<CountryInfo> countries = praytimes.cities.getCountries();
                        %>
                            <small class="form-text text-muted">Select from the countries you want to use:</small>
                        <%
                                for (CountryInfo countryInfo : countries) {
                            %>

                            <a href="?country=<%=countryInfo.name%>&has_regions=<%=(countryInfo.hasRegions ? "1" : "0") %>" class="list-group-item list-group-item-action city-item">
                                        <div class="d-flex w-100 justify-content-between">
                                                <h5 class="mb-1 name city-item-name"><%=countryInfo.name%></h5>
                                                <small><%=countryInfo.cityCount%> cities</small>
                                        </div>
                                </a>
                            <%
                                }
                            } catch (Exception e) {
                        %>
                            <div class="alert alert-danger">Error loading countries: <%=e.getMessage()%></div>
                        <%
                            }

                        } else if (has_regions.equals("1")){
                                try {
                                    List<RegionInfo> regions = praytimes.cities.getRegionsWithInfo(country);
                                %>
                                <small class="form-text text-muted">Select from the regions you want to use:</small>
                                <%
                                    for (RegionInfo regionInfo : regions) {
                                %>

                                    <a href="?country=<%=country%>&region=<%=regionInfo.code%>" class="list-group-item list-group-item-action city-item">
                                            <div class="d-flex w-100 justify-content-between">
                                                    <h5 class="mb-1 name city-item-name"><%=regionInfo.name%></h5>
                                            </div>
                                    </a>
                                <%
                                    }
                                } catch (Exception e) {
                                %>
                                    <div class="alert alert-danger">Error loading regions: <%=e.getMessage()%></div>
                                <%
                                }
                        } else {
                                try {
                                    Set<City> cities = praytimes.cities.get_cities(country, region);
                                    int i = 0;
                                %>
                                <small class="form-text text-muted">Select from the <%=String.format("%,d", cities.size())%> cities you want to use:
                                </small>
                                <%

				for (City city : cities) {
			%>

                                <a href="<%=city.url%>" class="list-group-item list-group-item-action city-item">
                                        <div class="d-flex w-100 justify-content-between">
                                                <h5 class="mb-1 name city-item-name"><%=city.name%></h5>
                                                <i class="fas fa-location-arrow"></i>
                                        </div>
                                        <p class="mb-1 city-item-country">
                                                <%=city.region%>
                                                <%=city.country%><br>
                                                <!--<%=city.timeZone%><br>-->
                                                <%=city.latitude%>&deg; N/S,
                                                <%=city.longitude%>&deg; E/W
                                        </p>
                                </a>
			<%
                                    // if (i++ > 00) break;
				}
                                } catch (Exception e) {
                                %>
                                    <div class="alert alert-danger">Error loading cities: <%=e.getMessage()%></div>
                                <%
                                }
                        }
			%>
		</div>
	</div>
	<script src="https://code.jquery.com/jquery-3.3.1.min.js" crossorigin="anonymous"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js"
		integrity="sha384-ZMP7rVo3mIykV+2+9J3UJ46jBk0WLaUAdn689aCwoqbBJiSnjAK/l8WvCWPIPm49" crossorigin="anonymous"></script>
	<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js"
		integrity="sha384-smHYKdLADwkXOn1EmN1qk/HfnUcbVRZyYmZ4qpPea6sjB/pTJ0euyQp0Mk8ck+5T" crossorigin="anonymous"></script>
</body>
</html>
