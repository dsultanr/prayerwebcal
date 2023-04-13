<%@page import="org.apache.commons.lang3.StringUtils"%>
<%@page import="java.util.*"%>
<%@page import="praytimes.Config"%>
<%@page contentType="text/html; charset=UTF-8"%>
<%
	Config cfg = new Config(request);
%>
<html>
<head>
	<title>Prayer Webcal Settings | Subscribe to your Personal World Prayer Times Calendar</title>
<%@include file="tags.jsp" %>
</head>
<body>
    <main role="main" class="container">

        <div class="header">
        	<div class="d-flex w-100 justify-content-between">
	            <div class="header__title">
	                <h1>Prayer Webcal</h1>
	                <h4>Calculation Settings</h4>
	            </div>
	            <div class="header__settings">
	                <div class="header__settings__icon pt-1">
	                	<a class="fas fa-times-circle d-inline" href="/"></a>
					</div>
	            </div>
            </div>
        </div>
        
		<div class="pl-3 pr-3">
			<form id="config" method="get" action="save.jsp" onsubmit="validate()">

		    <label class="form-text text-muted">Location name</label>
			<div class="input-group">
				<input name="l" oninput="validateNotBlank(this)" type="text" class="pl-1 pr-1 form-control form-control-sm"
					placeholder="Search city..." value="<%=cfg.getLocation()%>">
				<div class="input-group-append">
					<button class="btn btn-outline-secondary search-button" type="button"
						onclick="search(this.form.l.value)"><i class="fa fa-search"></i>
					</button>
				</div>
			</div>

		    <%
		    	if (cfg.isTimeZone()) {
			%>
		    	<label class="form-text text-muted">Time Zone</label>
			    <input name="tz" readonly type="text" class="form-control form-control-sm" placeholder="Time Zone" value="<%=cfg.getTimeZone()%>">
		    <%
		    	} else {
		    %>
		    	<label class="form-text text-muted">Time Zone Offset (deprecated)</label>
		    	<input name="z" readonly type="number" class="form-control form-control-sm" placeholder="Time Zone" value="<%=cfg.getTZDSTOffset()%>">
		    <%
		    	}
		    %>

			<div class="row">
				<div class="col">
				    <label class="form-text text-muted">Latitude (+/- &deg; N/S)</label>
				    <input name="x" readonly type="number" step="0.0000001" 
				    	title="Latitude must be a number" class="form-control form-control-sm" placeholder="Latitude" value="<%=cfg.getLatitude()%>">
		    	</div>
				<div class="col">		
				    <label class="form-text text-muted">Longitude  (+/- &deg; E/W)</label>
				    <input name="y" readonly type="number" step="0.0001"
				    	title="Latitude must be a number" class="form-control form-control-sm" placeholder="Longitude" value="<%=cfg.getLongitude()%>">
			    </div>
		    </div>

			<hr />
			<h6 class="mt-3">Juristic/Fiqh Settings</h6>

			<div class="prayers-preview text-center">
				<jsp:include page="timesMini.jsp" />
			</div>
			<div class="d-flex w-100 justify-content-within">
				<label>Date</label>
				<input name="when" type="hidden" value="">
				<input id="whend" type="range" class="custom-range" min="-365" max="366" step="1" value="0" oninput="setDateValue()">
				<label class="when-value"></label>
			</div>

			<input type="hidden" name="f" value="0">
			<label class="form-text text-muted">Select Fajr Angle</label>
			<div class="fv0-method">
				<div class="d-flex w-100 justify-content-within">
					<label>Fajr&deg;</label>
					<input name="fv" id="fv0" type="range" class="custom-range" min="14" max="20" step="0.1" value="<%=cfg.getFajrValue()%>" oninput="setSliderValue('fv0')">
					<label><span class="fv0-value">15</span>&deg;</label>
				</div>
			</div>

		    <label class="form-text text-muted">Select Asr method</label>
			<select class="form-control form-control-sm" name="j" value="<%=cfg.getAsrMethod()%>" oninput="setAsrMethod()">
			  <option value="0"<%=cfg.getAsrMethod()==0 ? "selected" : "" %>>Equal shadow length Asr (Shafi`i, Maliki, Hanbali, Ja`fari)</option>
			  <option value="1"<%=cfg.getAsrMethod()==1 ? "selected" : "" %>>Twice the shadow length Asr (Hanafi)</option>
			</select>

			<label class="form-text text-muted">Select Maghrib method</label>
			<select class="form-control form-control-sm" name="m" oninput="setMaghribMethod()">
			  <option value="0"<%=cfg.getMaghribMethod()==0 ? "selected" : "" %>>Angle-based Maghrib</option>
			  <option value="1"<%=cfg.getMaghribMethod()==1 ? "selected" : "" %>>Minutes after Sunset</option>
			</select>
			<div class="mv0-method">
				<div class="d-flex w-100 justify-content-within">
					<label>Maghrib&deg;</label>
					<input name="mv" id="mv0" type="range" class="custom-range" min="0.0" max="5.0" step="0.1" value="<%=cfg.getMaghribValue()%>" oninput="setSliderValue('mv0')">
					<label><span class="mv0-value">0</span>&deg;</label>
				</div>
			</div>
			<div class="mv1-method">
				<div class="d-flex w-100 justify-content-within">
					<label>Maghrib</label>
					<input name="mv" id="mv1" type="range" class="custom-range" min="0" max="20" step="1" value="<%=cfg.getMaghribValue()%>" oninput="setSliderValue('mv1')">
					<label><span class="mv1-value">0</span>&nbsp;mins.</label>
				</div>
			</div>
			
			<label class="form-text text-muted">Select Isha method</label>
			<select class="form-control form-control-sm" name="i" oninput="setIshaMethod()">
			  <option value="0"<%=cfg.getIshaMethod()==0 ? "selected" : "" %>>Angle-based Isha</option>
			  <option value="1"<%=cfg.getIshaMethod()==1 ? "selected" : "" %>>Minutes after Maghrib</option>
			</select>
			<div class="iv0-method">
				<div class="d-flex w-100 justify-content-within">
					<label>Isha&deg;</label>
					<input name="iv" id="iv0" type="range" class="custom-range" min="14.0" max="20.0" step="0.1" value="<%=cfg.getIshaValue()%>" oninput="setSliderValue('iv0')">
					<label><span class="iv0-value">15</span>&deg;</label>
				</div>
			</div>
			<div class="iv1-method">
				<div class="d-flex w-100 justify-content-within">
					<label>Isha</label>
					<input name="iv" id="iv1" type="range" class="custom-range" min="60" max="120" step="15" value="<%=cfg.getIshaValue()%>" oninput="setSliderValue('iv1')">
					<label><span class="iv1-value">90</span>&nbsp;mins.</label>
				</div>
			</div>

			<label class="form-text text-muted">Midnight method</label>
			<select class="form-control form-control-sm" name="mn" oninput="setMidnightMethod()">
			  <option value="0"<%=cfg.getMidnightMethod()==0 ? "selected" : "" %>>Midnight between Sunset and Sunrise</option>
			  <option value="1"<%=cfg.getMidnightMethod()==1 ? "selected" : "" %>>Midnight between Sunset and Fajr</option>
			</select>
			
			<label class="form-text text-muted">Altitude method</label>
			<select class="form-control form-control-sm" name="xm" oninput="setAltitudeMethod()">
			  <option value="3"<%=cfg.getHighAltitudeMethod()==3 ? "selected" : "" %>>Angle-based Fajr, Maghrib and Isha</option>
			  <option value="2"<%=cfg.getHighAltitudeMethod()==2 ? "selected" : "" %>>Isha at 2/7th and Fajr at 6/7th of the night</option>
			  <option value="1"<%=cfg.getHighAltitudeMethod()==1 ? "selected" : "" %>>Both Isha and Fajr at Midnight</option>
			  <option value="0"<%=cfg.getHighAltitudeMethod()==0 ? "selected" : "" %>>No adjustment</option>
			</select>
						
			<div class="mt-2 prayers-preview text-center">
				<jsp:include page="timesMini.jsp" />
			</div>

			<hr />
			<h6 class="mt-3">Minutes to Add</h6>
			
			<div class="d-flex w-100 justify-content-within">
				<label>Fajr</label>
				<input name="fo" id="fo" type="range" class="custom-range" min="-5" max="15" step="1" value="<%=cfg.getFajrOffset()%>" oninput="setSliderValue('fo')">
				<label><span class="fo-value">0</span>&nbsp;mins.</label>
			</div>
			<div class="d-flex w-100 justify-content-within">
				<label>Dhuhr</label>
				<input name="do" id="do" type="range" class="custom-range" min="-5" max="15" step="1" value="<%=cfg.getDhuhrOffset()%>" oninput="setSliderValue('do')">
				<label><span class="do-value">0</span>&nbsp;mins.</label>
			</div>
			<div class="d-flex w-100 justify-content-within">
				<label>Asr</label>
				<input name="ao" id="ao" type="range" class="custom-range" min="-5" max="15" step="1" value="<%=cfg.getAsrOffset()%>" oninput="setSliderValue('ao')">
				<label><span class="ao-value">0</span>&nbsp;mins.</label>
			</div>
			<div class="d-flex w-100 justify-content-within">
				<label>Maghrib</label>
				<input name="mo" id="mo" type="range" class="custom-range" min="-5" max="15" step="1" value="<%=cfg.getMaghribOffset()%>" oninput="setSliderValue('mo')">
				<label><span class="mo-value">0</span>&nbsp;mins.</label>
			</div>
			<div class="d-flex w-100 justify-content-within">
				<label>Isha</label>
				<input name="io" id="io" type="range" class="custom-range" min="-5" max="15" step="1" value="<%=cfg.getIshaOffset()%>" oninput="setSliderValue('io')">
				<label><span class="io-value">0</span>&nbsp;mins.</label>
			</div>
			<div class="d-flex w-100 justify-content-within">
				<label>Suhoor</label>
				<input name="so" id="so" type="range" class="custom-range" min="-90" max="5" step="5" value="<%=cfg.getSuhoorOffset()%>" oninput="setSliderValue('so')">
				<label><span class="so-value">0</span>&nbsp;mins.</label>
			</div>

			<hr />
			<h6 class="mt-3">Hide/show events in calendar</h6>
			<div class="pl-4 row">
				<label class="pr-2">
				  Show Sunrise alert in calendar
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Off</label>
					<input name="csr" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getSunriseAlert()%>">
					<label class="toggle-switch-on">On</label>
				</div>
			</div>
			<div class="pl-4 row">
				<label class="pr-2">
				  Show Sunset alert in calendar
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Off</label>
					<input name="cs" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getSunsetAlert()%>">
					<label class="toggle-switch-on">On</label>
				</div>
			</div>
			<div class="pl-4 row">
				<label class="pr-2">
				  Show Qiyam alert in calendar
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Off</label>
					<input name="cq" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getQiyamAlert()%>">
					<label class="toggle-switch-on">On</label>
				</div>
			</div>
			<div class="pl-4 row">
				<label class="pr-2">
				  Show Tahajjud alert in calendar
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Off</label>
					<input name="ct" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getTahajjudAlert()%>">
					<label class="toggle-switch-on">On</label>
				</div>
			</div>
			<div class="pl-4 row">
				<label class="pr-2">
				  Show Suhoor alert in calendar
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Off</label>
					<input name="csu" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getSuhoorAlert()%>">
					<label class="toggle-switch-on">On</label>
				</div>
			</div>

			<hr />
			<h6 class="mt-3">Miscellaneous</h6>
			<div class="pl-4 row">
				<label class="pr-2">
				  Jumaah on Fridays
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Off</label>
					<input name="js" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getJumaahSetting()%>">
					<label class="toggle-switch-on">On</label>
				</div>
			</div>
			<div class="pl-4 row">
				<label class="pr-2">
				  Isha delay on Ramadan
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Off</label>
					<input name="id" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getIshaRamadanSetting()%>">
					<label class="toggle-switch-on">On</label>
				</div>
			</div>
			<div class="pl-4 row">
                            <label class="form-text text-muted">Calendar event end time</label>
                            <select class="form-control form-control-sm" name="ee">
                              <option value="0"<%=cfg.getEventEnd()==0 ? "selected" : "" %>>0 minutes</option>
                              <option value="1"<%=cfg.getEventEnd()==1 ? "selected" : "" %>>20 minutes</option>
                              <option value="2"<%=cfg.getEventEnd()==2 ? "selected" : "" %>>30 minutes</option>
                              <option value="3"<%=cfg.getEventEnd()==3 ? "selected" : "" %>>40 minutes</option>
                              <option value="4"<%=cfg.getEventEnd()==4 ? "selected" : "" %>>Calculated preferred end time</option>
                              <!-- <option value="3"<%=cfg.getEventEnd()==3 ? "selected" : "" %>>Next pray start</option> -->
                              <!--<option value="0"<%=cfg.getEventEnd()==0 ? "selected" : "" %>>No adjustment</option>-->
                            </select>
                        </div>

			<div class="d-flex w-100 justify-content-within">
				<label>Number of months to export to calendar</label>
				<input name="nm" id="nm" type="range" class="custom-range" min="3" max="12" step="1" value="<%=cfg.getNumberOfMonthsSetting()%>" oninput="setSliderValue('nm')">
				<label><span class="nm-value">3</span>&nbsp;months.</label>
			</div>
			<div class="pl-4 row">
				<label class="pr-2">
				  Mark the Event as Free or Busy in calendar
				</label>
				<div class="ml-auto">
					<label class="toggle-switch-off">Free</label>
					<input name="es" type="range" class="custom-range toggle-switch" min="0" max="1" step="1" value="<%=cfg.getEventStatus()%>">
					<label class="toggle-switch-on">Busy</label>
				</div>
			</div>

			<p class="text-center mt-3 mb-5">
				<button role="button" class="btn btn-primary btn-lg"><i class="fas fa-check-circle"></i>&nbsp; Save</button>
				<a role="button" class="btn btn-outline-secondary btn-lg" href="javascript:window.history.go(-1);"><i class="fas fa-times-circle"></i>&nbsp; Cancel</a>
			</p>
			
		</form>
	
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
    <script src="https://code.jquery.com/jquery-3.3.1.min.js" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js" integrity="sha384-ZMP7rVo3mIykV+2+9J3UJ46jBk0WLaUAdn689aCwoqbBJiSnjAK/l8WvCWPIPm49" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js" integrity="sha384-smHYKdLADwkXOn1EmN1qk/HfnUcbVRZyYmZ4qpPea6sjB/pTJ0euyQp0Mk8ck+5T" crossorigin="anonymous"></script>

	<script type="text/javascript">
	
		function search(query) {
			window.location = '/search.jsp?query=' + query;
			return true;
		}
		
		function validateNotBlank(input) {
			if (input.value.match(/^\s*$/))
				input.setCustomValidity("Must not be blank.");
			else if (!input.value.match(/^[a-zA-Z0-9\,\.\-\_\s]+$/))
				input.setCustomValidity("Must not contain invalid characters.");
			else
				input.setCustomValidity("");
		}
		
		function validateNumeric(input) {
			if (input.value.match(/^[-+]?\d+(\.\d+)?$/) && parseFloat(input.value) > 0 || parseFloat(input.value) < 0)
				input.setCustomValidity("");
			else
				input.setCustomValidity("Must be a non-zero number.");
		}

		function validate() {
			var forms = document.forms[0];
			if (forms[0].checkValidity() === false) {
				return false;
			}
			forms[0].classList.add('was-validated');
			return true;
		}
		
		function setSliderValue(id) {
			$('.' + id + '-value').text($('#' + id).val());
			getTimesMini();
		}
		
		function setAsrMethod() {
			getTimesMini();
		}
		
		function setMaghribMethod() {
			var on = $('select[name="m"]').find(':selected').val();
			var off = (on=="0" ? "1" : "0");
			$('.mv' + on + '-method').show();
			$('#mv' + on).prop('disabled', false);
			$('.mv' + off + '-method').hide();
			$('#mv' + off).prop('disabled', true);
			setSliderValue('mv' + on);
		}
		
		function setIshaMethod() {
			var on = $('select[name="i"]').find(':selected').val();
			var off = (on=="0" ? "1" : "0");
			$('.iv' + on + '-method').show();
			$('#iv' + on).prop("disabled", false);
			$('.iv' + off + '-method').hide();
			$('#iv' + off).prop("disabled", true);
			setSliderValue('iv' + on);
		}
		
		function setMidnightMethod() {
			getTimesMini();
		}
		
		function setAltitudeMethod() {
			var method = $('select[name="xm"]').find(':selected').val();
			var angleBased = (method == "3");
			getTimesMini();
		}
		
		function toggleValue(el) {
			el.value = (parseInt(el.value)+1) % 2;
			if (el.value == 0)
				$('input[name="'+ el.name +'"]').prop('checked', false);
			else
				$('input[name="'+ el.name +'"]').prop('checked', true);
		}
		
		function getTimesMini() {
			$.get('timesMini.jsp' + getQueryString(), function(data) {
				$('.prayers-preview').html(data);
			});
		}
		
		function setDateValue() {
			var when = new Date();
			var add = parseInt($('#whend').val());
			when.setDate(when.getDate() + add);
			when.setMinutes(0);
			when.setSeconds(0);
			when.setMilliseconds(0);
			$('input[name="when"]').val(when.toISOString());
			$('.when-value').text((when.getMonth()+1) + '/' + when.getDate());
			getTimesMini();
		}
		
		function getQueryString() {
			var qs = '';
			var form = document.forms[0];
			for (var i=0; i < form.elements.length; i++) {
			    var el = form.elements[i];
			    if (el && el.name !== '') {
			    	if (qs !== '')
			    		qs += '&';
			    	if (el.name == 'm' || el.name == 'i') {
			    		qs += el.name + '=' + el.value;
			    		qs += '&' + el.name + 'v=' + getArrayValue(el);
			    	} else
			    		qs += el.name + '=' + encodeURI(el.value);
			    }
			}
			return '?' + qs;
		}
		
		function getArrayValue(el) {
			return document.getElementById(el.name + 'v' + el.value).value;
		}
		
		$('input[name="l"]').bind('keypress', function(e){
			if(e.keyCode == 13) { e.preventDefault(); }
		});
		
		setDateValue();
		setAltitudeMethod();
		setSliderValue('fv0');
		setMaghribMethod();
		setIshaMethod();
		setMidnightMethod();
		setSliderValue('fo');
		setSliderValue('do');
		setSliderValue('ao');
		setSliderValue('mo');
		setSliderValue('io');
		setSliderValue('so');
		setSliderValue('nm');
						
	</script>


</body>
</html>

