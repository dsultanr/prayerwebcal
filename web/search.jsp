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
    <script>
      (g=>{var h,a,k,p="The Google Maps JavaScript API",c="google",l="importLibrary",q="__ib__",m=document,b=window;b=b[c]||(b[c]={});var d=b.maps||(b.maps={}),r=new Set,e=new URLSearchParams,u=()=>h||(h=new Promise(async(f,n)=>{await (a=m.createElement("script"));e.set("libraries",[...r]+"");for(k in g)e.set(k.replace(/[A-Z]/g,t=>"_"+t[0].toLowerCase()),g[k]);e.set("callback",c+".maps."+q);a.src=`https://maps.googleapis.com/maps/api/js?`+e;d[q]=f;a.onerror=()=>h=n(Error(p+" could not load."));a.nonce=m.querySelector("script[nonce]")?.nonce||"";m.head.append(a)}));d[l]?console.warn(p+" only loads once. Ignoring:",g):d[l]=(f,...n)=>r.add(f)&&u().then(()=>d[l](f,...n))})({
        key: "AIzaSyBNz393sQh34sDpfOQ4V9bscDYADOjwLkY",
        v: "weekly",
        // Use the 'v' parameter to indicate the version to use (weekly, beta, alpha, etc.).
        // Add other bootstrap parameters as needed, using camel case.
      });
    </script>

	<script>
	
		async function search() {
                    const { Place } = await google.maps.importLibrary("places");
                    
                    const request = {
                      textQuery: $('#query').val(),
                      fields: ["displayName", "location", "addressComponents"],
                      includedType: "locality",
                    };

                    $('.search-button').html('<i class="fas fa-spinner fa-pulse"></i>');
                    const { places } = await Place.searchByText(request);
  
//                    const { places } = await Place.searchByText(request);

                    if (places.length) {
                      console.log(places);

                      const { LatLngBounds } = await google.maps.importLibrary("core");
                      const bounds = new LatLngBounds();

                      // Loop through and get all the results.
                      places.forEach((place) => {
                        console.log("findPlaces",place.displayName,place.location.lat(),place.location.lng());
                        showResults(place);
                      });
                      
                    } else {
                      console.log("No results");
                        $(".list-group").append(
                                '<div class="list-group-item city-item">'
                                + '<p class="mb-1 city-item-country">Cannot find this location</p>'
                                + '</div>'
                        );
                    }
			
//                        var service = new google.maps.places.PlacesService(new google.maps.Map(document.getElementById('map')));
//			var q = $('#query').val();
//			if (q.trim().match(/[a-zA-Z]/)) {
//				$('.search-button').html('<i class="fas fa-spinner fa-pulse"></i>');
//				service.textSearch({
//						query: q,
//						type: 'locality'
//					}, showResults);
//			} else
//				console.log('not searching ' + query);
		}
		
		function showResults(place) {
			$('.search-button').html('<i class="fa fa-search"></i>');
			$('.search-results').show();
			$(".list-group").html("");
                        var geo = place.location;
                        var x = Math.round(geo.lat() * 1000) / 1000.
                        var y = Math.round(geo.lng() * 1000) / 1000.
                        var formatted_address = "";
                        place.addressComponents.forEach((addressComponent) => {
                            if (addressComponent.Eg[0] == "locality" || addressComponent.Eg[0] == "country" || addressComponent.Eg[0].indexOf("administrative_area") !== -1)
                            formatted_address += addressComponent.Fg + " ";
                        });

                        $(".list-group").append(
                                '<a href="#" onclick="save('
                                                + '\'' + place.displayName + ', ' + formatted_address + '\''
                                                + ',' + x
                                                + ',' + y
                                                + ');" class="list-group-item list-group-item-action city-item">'
                                + '<div class="d-flex w-100 justify-content-between">'
                                + '   <h5 class="mb-1 name city-item-name">' + place.displayName + '</h5>'
                                + '   <i class="fas fa-location-arrow"></i>'
                                + '</div>'
                                + '<p class="mb-1 city-item-country">'
                                                + formatted_address
                                                + '<br>' + x + '&deg N, ' + y + '&deg E'
                                + '</p>'
                                + '</a>'
                        );
                            
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

