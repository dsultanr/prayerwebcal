function getLocation() {
	try {
		var config = document.getElementById("config");
		config.z.value = new Date().getTimezoneOffset() * -1;
		if (navigator.geolocation)
			navigator.geolocation.getCurrentPosition(positionSuccessHandler,
					positionErrorHandler);
	} catch (error) {
		$(".alert-warning .message").text(message);
		$(".alert-warning").show();
	}
}

function positionSuccessHandler(position) {
	var config = document.getElementById("config");
	config.x.value = Math.round(position.coords.latitude * 1000) / 1000;
	config.y.value = Math.round(position.coords.longitude * 1000) / 1000;
	$(".alert-success .message").text("Detected current location.");
	$(".alert-success").show();
}

function positionErrorHandler(error) {
	var message = "";
	switch (error.code) {
	case error.PERMISSION_DENIED:
		message = "This website does not have permission to use "
				+ "the Geolocation API. Please enter the latitude and longitude of your current location.";
		break;
	case error.POSITION_UNAVAILABLE:
		message = "Your current location could not be determined. Please enter the latitude and longitude of your current location.";
		break;
	case error.PERMISSION_DENIED_TIMEOUT:
		message = "The current position could not be determined "
				+ "within the specified timeout period.";
		break;
	}
	if (message == "") {
		var strErrorCode = error.code.toString();
		message = "Your current location could not be determined due to "
				+ "an unknown error (Code: " + strErrorCode + ").";
	}
	$(".alert-warning .message").text(message);
	$(".alert-warning").show();
}
