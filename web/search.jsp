<%@page import="org.apache.commons.lang3.StringUtils"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="edu.emory.mathcs.backport.java.util.concurrent.TimeUnit"%>
<%@page import="java.util.TimeZone"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.time.LocalDate"%>
<%@page import="java.time.LocalDateTime"%>
<%@page import="java.time.ZoneId"%>
<%@page import="java.time.ZonedDateTime"%>
<%@page import="java.io.FileReader"%>
<%@page import="java.io.BufferedReader"%>
<%@page contentType="text/html; charset=UTF-8"%>
<html>
<head>
    <title>Prayer Webcal Location Search | Subscribe to your Personal World Prayer Times Calendar</title>
    <% if (request.getRequestURI().contains("search.jsp")) { %>
        <%@include file="tagnoindex.jsp" %>
    <% } %>
<%@include file="tags.jsp" %>
</head>
<body>

    <main role="main" class="container">

        <div class="header row">
         	<div class="d-flex w-100 justify-content-between">
	            <div class="header__title">
	                <h1>Prayer Webcal</h1>
	                <h4>Location Search</h4>
	            </div>
	            <div class="header__settings">
	                <div class="header__settings__icon pt-1">
	                	<a class="fas fa-times-circle d-inline" href="/"></a>
					</div>
	            </div>
            </div>
        </div>
        
        <%
        	String query = StringUtils.defaultString(request.getParameter("query"), "").trim().replace("_", " ");
        %>
		<div class="pl-3 pr-3">
			<form id="search" method="get" action="/search.jsp">
				<small class="form-text text-muted">Enter name of city to search</small>
				<div class="input-group">
					<input required type="search" name="query" id="query" class="pl-1 pr-1 form-control"
						placeholder="Search city..." value="<%=query%>" />
					<div class="input-group-append">
						<button class="btn btn-outline-secondary search-button" type="submit"><i class="fa fa-search"></i></button>
					</div>
				</div>
			</form>
			
			<div class="search-results" style="display:none;">
				<small class="form-text text-muted">Select the city you want to use:</small>
				<div class="list-group city-list"></div>
			</div>
			
		</div>
		
		<div id="map" class="d-none"></div>
		
		<div class="text-center mt-3">
			<img title="Powered by Google" src="/res/powered_by_google_on_white.png" />
		</div>
	
		<!-- Global site tag (gtag.js) - Google Analytics -->
		<script async src="https://www.googletagmanager.com/gtag/js?id=UA-10540377-3"></script>
		<script>
		  window.dataLayer = window.dataLayer || [];
		  function gtag(){dataLayer.push(arguments);}
		  gtag('js', new Date());
		  gtag('config', 'UA-10540377-3');
		</script>

	</main>
    <script src="/res/jquery-3.3.1.min.js"></script>
    <script src="/res/popper.min.js"></script>
    <script src="/res/bootstrap.min.js"></script>
    <script src="/res/axios.min.js"></script>
	<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDamF5CNh-zCpptxxU-iceihfn8L4t1E00&libraries=places"></script>
	<script>
	
		function search() {
			var service = new google.maps.places.PlacesService(new google.maps.Map(document.getElementById('map')));
			var q = $('#query').val();
			if (q.trim().match(/[a-zA-Z]/)) {
				$('.search-button').html('<i class="fas fa-spinner fa-pulse"></i>');
				service.textSearch({
						query: q,
						type: 'locality'
					}, showResults);
			} else
				console.log('not searching ' + query);
		}
		
		function showResults(results, status) {
			$('.search-button').html('<i class="fa fa-search"></i>');
			$('.search-results').show();
			$(".list-group").html("");
			$.each(results, function(index, item) {
				var geo = item.geometry.location;
				var x = Math.round(geo.lat() * 1000) / 1000.
				var y = Math.round(geo.lng() * 1000) / 1000.
				$(".list-group").append(
					'<a href="#" onclick="save('
							+ '\'' + item.name + ', ' + item.formatted_address + '\''
							+ ',' + x
							+ ',' + y
							+ ');" class="list-group-item list-group-item-action city-item">'
					+ '<div class="d-flex w-100 justify-content-between">'
					+ '   <h5 class="mb-1 name city-item-name">' + item.name + '</h5>'
					+ '   <i class="fas fa-location-arrow"></i>'
					+ '</div>'
					+ '<p class="mb-1 city-item-country">'
							+ item.formatted_address
							+ '<br>' + x + '&deg N, ' + y + '&deg E'
					+ '</p>'
					+ '</a>'
				);
			})
			if (results.length == 0) {
				$(".list-group").append(
					'<div class="list-group-item city-item">'
					+ '<p class="mb-1 city-item-country">Cannot find this location</p>'
					+ '</div>'
				);
			}
		}
var geocoder;

function initialize() {
  geocoder = new google.maps.Geocoder();

}

function codeLatLng(lat, lng) {
  var latlng = new google.maps.LatLng(lat, lng);
  geocoder.geocode({latLng: latlng}, function(results, status) {
    if (status == google.maps.GeocoderStatus.OK) {
      if (results[1]) {
        var arrAddress = results;
        console.log(results);
        $.each(arrAddress, function(i, address_component) {
          if (address_component.types[0] == "locality") {
            console.log("City: " + address_component.address_components[0].long_name);
            itemLocality = address_component.address_components[0].long_name;
          }
        });
      } else {
        alert("No results found");
      }
    } else {
      alert("Geocoder failed due to: " + status);
    }
  });
}
		function save(l, x, y) {
			$('.search-button').html('<i class="fas fa-spinner fa-pulse"></i>');
			var tz = "America/New_York";
                            $.getJSON(
			    	'/timezone?x='
		    		+ x + '&y=' + y
		    		+'&timestamp=' + new Date().getTime() / 1000.
					+'&key=AIzaSyDamF5CNh-zCpptxxU-iceihfn8L4t1E00', 
					function(data) {
//			    		console.log(JSON.stringify(data));
			    		tz = data.timeZoneId;
	  				}).done(function() {
	  					var url = 'save.jsp?l=' + l + '&x=' + x + '&y=' + y + '&tz=' + tz;
	  					window.location = url;
	  				});
		}

		$("input[type='search']").on("click", function () {
			   $(this).select();
			});		
		$("input[type='search']").focus();
		
		search();
		
	</script>
</body>
</html>

