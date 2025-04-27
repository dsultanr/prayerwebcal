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
                let query = $('#query').val().trim();
                if (!query) return;

                $(".search-button").html('<i class="fas fa-spinner fa-pulse"></i>');

                try {
                    const response = await fetch(`https://nominatim.openstreetmap.org/search?q=\${encodeURIComponent(query)}&format=json&addressdetails=1&limit=5`);

                    const places = await response.json();

                    $(".list-group").html("");
                    $(".search-results").show();

                    if (!places.length) {
                        $(".list-group").append('<div class="list-group-item list-group-item-action disabled">Cannot find this location</div>');
                        $(".search-button").html('<i class="fas fa-search"></i>');
                        return;
                    }

                    places.forEach((place) => {
                        console.log(place)
                        let addressType = place.addresstype
//                        let displayName = place.address.amenity || place.address.city || place.address.town || place.address.village || place.address.state || "Unknown";
                        let displayName = place.address[place.addresstype] || "Unknown"
                        let country = place.address.country || "";
//                        let formattedAddress = `\${country}`.trim();
                        let formattedAddress = place.display_name;

                        let lat = parseFloat(place.lat);
                        let lon = parseFloat(place.lon);

                        let x = Math.round(lat * 1000) / 1000;
                        let y = Math.round(lon * 1000) / 1000;

                        $(".list-group").append(`
                            <a href="#" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center city-item"
                               onclick="save('\${displayName}', \${x}, \${y});">
                               <div>
                                  <h5 class="mb-1 name city-item-name">\${displayName}</h5>
                                  <p class="mb-1 city-item-country">\${formattedAddress}<br>\${x}° N, \${y}° E</p>
                               </div>
                               <i class="fas fa-location-arrow"></i>
                            </a>
                        `);
                    });

                } catch (error) {
                    console.error(error);
                    $(".list-group").html('<div class="list-group-item list-group-item-action disabled">Error loading locations</div>');
                } finally {
                    $(".search-button").html('<i class="fas fa-search"></i>');
                }
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
                                                + '\'' + place.displayName  + '\''
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

async function fetchWithTimeout(resource, options = {}) {
    const { timeout = 5000 } = options; // 5000 мс = 5 секунд таймаут

    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeout);

    const response = await fetch(resource, {
        ...options,
        signal: controller.signal
    });

    clearTimeout(id);
    return response;
}

    async function save(l, x, y) {
    $(".search-button").html('<i class="fas fa-spinner fa-pulse"></i>');

    let tz = "America/New_York"; // дефолт

    try {
        let success = false;

        try {
            const geoResponse = await fetchWithTimeout(`https://api.geonames.org/timezoneJSON?lat=\${x}&lng=\${y}&username=dsultanr`, { timeout: 5000 });
            const geoData = await geoResponse.json();

            if (geoData && geoData.timezoneId) {
                tz = geoData.timezoneId;
                success = true;
            }
        } catch (e) {
            console.warn("GeoNames failed:", e);
        }

        if (!success) {
            try {
                const tzdbResponse = await fetchWithTimeout(`https://api.timezonedb.com/v2.1/get-time-zone?key=TXX5G17GA9J9&format=json&by=position&lat=\${x}&lng=\${y}`, { timeout: 5000 });
                const tzdbData = await tzdbResponse.json();

                if (tzdbData && tzdbData.zoneName) {
                    tz = tzdbData.zoneName;
                    success = true;
                }
            } catch (e) {
                console.warn("TimeZoneDB failed:", e);
            }
        }

        if (!success) {
            alert("Can't find Timezone for " + l);
            return;
        }

    } catch (error) {
        console.error("Unexpected error in save():", error);
        alert("Can't find Timezone for " + l);
        return;
    }

    const url = `save.jsp?l=\${encodeURIComponent(l)}&x=\${x}&y=\${y}&tz=\${encodeURIComponent(tz)}`;
    window.location = url;
}


		$("input[type='search']").on("click", function () {
			   $(this).select();
			});		
		$("input[type='search']").focus();
		
		search();
		
	</script>
</body>
</html>

