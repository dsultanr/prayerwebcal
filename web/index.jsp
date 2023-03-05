<%@page import="edu.emory.mathcs.backport.java.util.Collections"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.logging.Logger"%>
<%@page import="java.util.Arrays"%>
<%@page import="java.time.chrono.HijrahDate"%>
<%@page import="java.util.TimeZone"%>
<%@page import="java.time.ZoneOffset"%>
<%@page import="java.util.concurrent.TimeUnit"%>
<%@page import="java.time.temporal.ChronoField"%>
<%@page import="java.time.ZoneId"%>
<%@page import="java.time.OffsetDateTime"%>
<%@page import="java.util.Locale"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.text.DateFormat"%>
<%@page import="java.util.Date"%>
<%@page import="praytimes.PrayEvent"%>
<%@page import="praytimes.CalendarIterator"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.util.List"%>
<%@page import="praytimes.Config"%>
<%@page contentType="text/html; charset=UTF-8" %>
<%
	Logger log = Logger.getLogger("jsp.index");
	Config cfg = (Config) request.getAttribute("cfg");
	if (cfg == null)
		cfg = new Config(request);
	else
		log.fine("loading cfg from request");
	cfg.store(response);
	OffsetDateTime now = 
//			OffsetDateTime.of(2022, 12, 16, 17, 18, 0, 0, ZoneOffset.ofHours(4));
			OffsetDateTime.now(ZoneId.of("UTC"));
	now = now.withOffsetSameLocal(ZoneOffset.ofTotalSeconds(cfg.getTZDSTOffset() * 60));
	now = now.plusMinutes(cfg.getTZDSTOffset());
	OffsetDateTime yesterdayNow = now.minusDays(1);
	OffsetDateTime tomorrowNow = now.plusDays(1);
	
	Calendar nowCal = Calendar.getInstance();
	nowCal.setTime(Date.from(now.toInstant()));
	Calendar yesterdayCal = Calendar.getInstance();
	yesterdayCal.setTime(Date.from(yesterdayNow.toInstant()));
	Calendar tomorrowCal = Calendar.getInstance();
	tomorrowCal.setTime(Date.from(tomorrowNow.toInstant()));
	
	List<String> todayTimes = cfg.getFactory().getPrayerTimes(nowCal, cfg.getLatitude(), cfg.getLongitude(), 0.0);
	List<String> yesterdayTimes = cfg.getFactory().getPrayerTimes(yesterdayCal, cfg.getLatitude(), cfg.getLongitude(), 0.0);
	List<String> tomorrowTimes = cfg.getFactory().getPrayerTimes(tomorrowCal, cfg.getLatitude(), cfg.getLongitude(), 0.0);	
	
	List<PrayEvent> prayers = new ArrayList<PrayEvent>();
	PrayEvent fajr = new PrayEvent(cfg, PrayEvent.Type.Fajr, now, todayTimes.get(PrayEvent.Type.Fajr.ordinal()));
	PrayEvent suhoor = PrayEvent.getSuhoorEvent(now, fajr);
	PrayEvent sunrise = new PrayEvent(cfg, PrayEvent.Type.Sunrise, now, todayTimes.get(PrayEvent.Type.Sunrise.ordinal()));
	PrayEvent afterSunrise = new PrayEvent(cfg, PrayEvent.Type.EndingEvent, now, sunrise.getStartTime().plusMinutes(20));
	PrayEvent dhuhr = new PrayEvent(cfg, PrayEvent.Type.Dhuhr, now, todayTimes.get(PrayEvent.Type.Dhuhr.ordinal()));
	PrayEvent asr = new PrayEvent(cfg, PrayEvent.Type.Asr, now, todayTimes.get(PrayEvent.Type.Asr.ordinal()));
	PrayEvent sunset = new PrayEvent(cfg, PrayEvent.Type.Sunset, now, todayTimes.get(PrayEvent.Type.Sunset.ordinal()));
	PrayEvent maghrib = new PrayEvent(cfg, PrayEvent.Type.Maghrib, now, todayTimes.get(PrayEvent.Type.Maghrib.ordinal()));
	PrayEvent isha = new PrayEvent(cfg, PrayEvent.Type.Isha, now, todayTimes.get(PrayEvent.Type.Isha.ordinal()));
	if (now.getHour() >= 0 && now.isBefore(suhoor.getStartTime())) {
		PrayEvent prevSunset = new PrayEvent(cfg, PrayEvent.Type.Sunset, yesterdayNow, yesterdayTimes.get(PrayEvent.Type.Sunset.ordinal()));
		PrayEvent prevMaghrib = new PrayEvent(cfg, PrayEvent.Type.Maghrib, yesterdayNow, yesterdayTimes.get(PrayEvent.Type.Maghrib.ordinal()));
		PrayEvent prevIsha = new PrayEvent(cfg, PrayEvent.Type.Isha, yesterdayNow, yesterdayTimes.get(PrayEvent.Type.Isha.ordinal()));
		PrayEvent qiyam = PrayEvent.getQiyamEvent(now, prevSunset, fajr, sunrise);
		PrayEvent tahajjud = PrayEvent.getTahajjudEvent(now, prevSunset, fajr, sunrise);
		prevMaghrib.setNextEvent(prevIsha);
		prayers.add(prevIsha.setPrevEvent(prevMaghrib).setNextEvent(qiyam));
		prayers.add(qiyam.setPrevEvent(prevIsha).setNextEvent(tahajjud));
		prayers.add(tahajjud.setPrevEvent(qiyam).setNextEvent(suhoor));
		prayers.add(suhoor.setPrevEvent(tahajjud).setNextEvent(fajr));
		prayers.add(fajr.setPrevEvent(suhoor).setNextEvent(sunrise));
		prayers.add(sunrise.setPrevEvent(fajr).setNextEvent(afterSunrise));
		prayers.add(afterSunrise.setPrevEvent(sunrise).setNextEvent(dhuhr));
		prayers.add(dhuhr.setPrevEvent(afterSunrise).setNextEvent(asr));
		prayers.add(asr.setPrevEvent(dhuhr).setNextEvent(sunset));
		prayers.add(sunset.setPrevEvent(asr).setNextEvent(maghrib));
		prayers.add(maghrib.setPrevEvent(sunset).setNextEvent(isha));
		isha.setPrevEvent(maghrib);
	} else {
		PrayEvent prevSunset = new PrayEvent(cfg, PrayEvent.Type.Sunset, now, yesterdayTimes.get(PrayEvent.Type.Sunset.ordinal()));
		PrayEvent prevMaghrib = new PrayEvent(cfg, PrayEvent.Type.Maghrib, now, yesterdayTimes.get(PrayEvent.Type.Maghrib.ordinal()));
		PrayEvent nextFajr = new PrayEvent(cfg, PrayEvent.Type.Fajr, tomorrowNow, tomorrowTimes.get(PrayEvent.Type.Fajr.ordinal()));
		PrayEvent nextSunrise = new PrayEvent(cfg, PrayEvent.Type.Sunrise, tomorrowNow, tomorrowTimes.get(PrayEvent.Type.Sunrise.ordinal()));
		PrayEvent nextSuhoor = PrayEvent.getSuhoorEvent(tomorrowNow, nextFajr);
		PrayEvent qiyam = PrayEvent.getQiyamEvent(now, sunset, nextFajr, nextSunrise);
		PrayEvent tahajjud = PrayEvent.getTahajjudEvent(now, sunset, nextFajr, nextSunrise);
		PrayEvent prevTahajjud = PrayEvent.getTahajjudEvent(now, prevSunset, fajr, sunrise);
		prevTahajjud.setNextEvent(suhoor);
		prayers.add(suhoor.setPrevEvent(prevTahajjud).setNextEvent(fajr));
		prayers.add(fajr.setPrevEvent(suhoor).setNextEvent(sunrise));
		prayers.add(sunrise.setPrevEvent(fajr).setNextEvent(afterSunrise));
		prayers.add(afterSunrise.setPrevEvent(sunrise).setNextEvent(dhuhr));
		prayers.add(dhuhr.setPrevEvent(afterSunrise).setNextEvent(asr));
		prayers.add(asr.setPrevEvent(dhuhr).setNextEvent(sunset));
		prayers.add(sunset.setPrevEvent(asr).setNextEvent(maghrib));
		prayers.add(maghrib.setPrevEvent(sunset).setNextEvent(isha));
		prayers.add(isha.setPrevEvent(maghrib).setNextEvent(qiyam));
		prayers.add(qiyam.setPrevEvent(isha).setNextEvent(tahajjud));
		prayers.add(tahajjud.setPrevEvent(qiyam).setNextEvent(nextSuhoor));
		prayers.add(nextSuhoor.setPrevEvent(tahajjud).setNextEvent(nextFajr));
		nextFajr.setPrevEvent(tahajjud);
	}
	Collections.sort(prayers);
%>
<html>
<head>
	<title>
		<%
			if (cfg.getLocation() == null) {
		%>
		Subscribe to your Personal World Prayer Times Calendar | Prayer Webcal
		<%
			} else {
		%>
		Prayer Webcal | <%=cfg.getLocation()%> Prayer Timings
		<%
			}
		%>
	</title>
	<link rel="canonical" href="https://prayerwebcal.dsultan.com<%=cfg.getPath()%>" />
<%@include file="tags.jsp" %>
	<script type="application/ld+json">
		{
			"@context": "http://schema.org",
			"@type": "Place",
			"geo": {
				"@type": "GeoCoordinates",
				"latitude": "<%=cfg.getLatitude()%>",
				"longitude": "<%=cfg.getLongitude()%>"
			},
			"address": "<%=cfg.getLocation()%>",
			"name": "<%=cfg.getLocation()%>"
		}
	</script>

</head>
<body>

    <main role="main" class="container">

        <div class="header">
        	<div class="d-flex w-100 justify-content-between">
	            <div class="header__title">
	            	<h1 class="">Prayer Times <%=cfg.getLocation()%></h1>
	                <h3 class="header__title__date"><%=HijrahDate.from(now).format(PrayEvent.DATE)%></h3>
	                <p class="header__title__text"><%=now.format(PrayEvent.DATE) + " " + now.format(PrayEvent.TIME).toLowerCase()%></p>
	            </div>
	            <div class="header__settings">
	                <div class="header__settings__icon text-nowrap">
	               		<a title="Facebook" class="fab fa-facebook" href="https://www.facebook.com/prayerwebcal"></a>
	                	&nbsp;
	               		<a title="Subscribe to Prayer Times Alerts" class="fas fa-calendar-plus webcal-button" href=""></a>
	                	&nbsp;
	                	<a title="Fine Tune" class="fa fa-cog" href="/settings.jsp"></a>
					</div>
	            </div>
            </div>
			<div class="header__search header__title__loc">
				<a href="/search.jsp?query=<%=cfg.getLocation()%>">
	                <h4 class="header__title__subtitle" title="(<%=cfg.getLatitude()%>&deg;,<%=cfg.getLongitude()%>&deg;)">
	                	<%=cfg.getLocation()%>
	                </h4>
					<div class="w-100"><i class="fa fa-search"></i> Search location</div>
				</a>
                                OR 
                                <a href="/locations.jsp">
                                    <div class="w-100"><i class="fa fa-list"></i> Select location from the list</div>
                                </a>
			</div>
        </div>

		<%
			if (request.getAttribute("alert") != null) {
		%>
			<p class="alert alert-warning alert-dismissible fade show" role="alert"><small>
				<strong>NOTE:</strong> <%=request.getAttribute("alert")%>
				<button type="button" class="close" data-dismiss="alert" aria-label="Close">
		 			<span>&times;</span>
		 		</button>
			</small></p>
		<%
			}
		%>

        <ul class="events">
			<%
				for (PrayEvent prayer : prayers) {
					if (prayer.getType() == PrayEvent.Type.EndingEvent || prayer.getType() == PrayEvent.Type.InvalidEvent)
						continue;
					if (prayer.getStartTime().isEqual(prayer.getNextEvent().getStartTime()))
						continue;
					if (fajr.getType() == PrayEvent.Type.InvalidEvent) {
						if (prayer.getType() == PrayEvent.Type.Qiyam || prayer.getType() == PrayEvent.Type.Tahajjud
								|| prayer.getType() == PrayEvent.Type.Suhoor)
							continue;
					}
					boolean activePrayer = prayer.isActive(now);
					String active = activePrayer ? "active": "";
			%>
            <li class="events__item events__item-<%=prayer.getType().getEventType()%> <%=active%>">
            	<div class="row">
	                <div class="events__item__desc col">
						<script type="application/ld+json">
							{
								"@context": "http://schema.org",
								"@type": "Event",
								"location" : {
									"@type": "Place",
									"geo": {
										"@type": "GeoCoordinates",
										"latitude": "<%=cfg.getLatitude()%>",
										"longitude": "<%=cfg.getLongitude()%>"
									},
									"address": "<%=cfg.getLocation()%>",
									"name": "<%=cfg.getLocation()%>"
								},
								"name": "<%=prayer.getName()%> <%=prayer.getFriendlyConfig()%> in <%=cfg.getLocation()%>",
								"description": "<%=cfg.toStringNoDefaults()%>",
								"startDate": "<%=prayer.getStartTime()%>",
								"endDate": "<%=prayer.getEndTime()%>"
							}
						</script>
	                    <div class="events__item__desc__title">
	                    	<%=prayer.getName()%>
	                    </div>
	                    <div class="events__item__desc__subtitle" title="<%=prayer.getFormattedDate()%> <%=prayer.getFormattedTime()%>">
	                    	<%=prayer.getFormattedTime()%>
	                    	<%
	                    		if (prayer.getType().getEventType() != PrayEvent.Event.NonPrayer || prayer.getType() == PrayEvent.Type.Suhoor) {
	                    	%>
	                    		<span class="cfg"><%=prayer.getFriendlyConfig()%></span>
	                    	<%
								}
							%>
	                    </div>
	                </div>
	                <div class="events__item__icon <%=active%> col">
	                    <%
	                    	if (prayer.getType() == PrayEvent.Type.Suhoor) {
	                    %>
	                	<svg xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" version="1.1" x="0px" y="0px" viewBox="0 0 100 100"><g transform="translate(0,-952.36218)"><path style="text-indent:0;text-transform:none;direction:ltr;block-progression:tb;baseline-shift:baseline;color:#000000;enable-background:accumulate;" d="m 21.21885,968.33833 a 2.0002,2.0002 0 0 1 1.78125,2.0312 l 0,16.00004 c 0,4.8172 -3.45151,8.8769 -8,9.8125 l 0,38.18753 a 2.0002,2.0002 0 1 1 -4,0 l 0,-38.18753 c -4.54849,-0.9356 -8,-4.9953 -8,-9.8125 l 0,-16.00004 a 2.0002,2.0002 0 1 1 4,0 l 0,16.00004 c 0,2.6552 1.64898,4.8796 4,5.6875 l 0,-21.68754 a 2.0002,2.0002 0 0 1 2.21875,-2.0312 2.0002,2.0002 0 0 1 1.78125,2.0312 l 0,21.68754 c 2.35102,-0.8079 4,-3.0323 4,-5.6875 l 0,-16.00004 a 2.0002,2.0002 0 0 1 2.21875,-2.0312 z m 65.78125,0.0312 c 3.01977,0 5.60433,1.844 7.3125,4.4062 1.70817,2.5623 2.6875,5.9198 2.6875,9.5938 0,3.674 -0.97933,7.03154 -2.6875,9.59384 -1.31823,1.9773 -3.15316,3.5205 -5.3125,4.125 l 0,38.28123 a 2.0002,2.0002 0 1 1 -4,0 l 0,-38.28123 c -2.15934,-0.6045 -3.99427,-2.1477 -5.3125,-4.125 -1.70817,-2.5623 -2.6875,-5.91984 -2.6875,-9.59384 0,-3.674 0.97933,-7.0315 2.6875,-9.5938 1.70817,-2.5622 4.29273,-4.4062 7.3125,-4.4062 z m 0,4 c -1.39843,0 -2.81272,0.8441 -4,2.625 -1.18728,1.7809 -2,4.4216 -2,7.375 0,2.9534 0.81272,5.59414 2,7.37504 1.18728,1.7809 2.60157,2.625 4,2.625 1.39843,0 2.81272,-0.8441 4,-2.625 1.18728,-1.7809 2,-4.42164 2,-7.37504 0,-2.9534 -0.81272,-5.5941 -2,-7.375 -1.18728,-1.7809 -2.60157,-2.625 -4,-2.625 z m -37,8 c 15.44029,0 28,12.55984 28,28.00007 0,15.4402 -12.5597,28 -28,28 -15.44021,0 -28,-12.5598 -28,-28 0,-15.44023 12.55979,-28.00007 28,-28.00007 z m 0,4 c -13.27843,0 -24,10.72154 -24,24.00007 0,13.2784 10.72157,24 24,24 13.27852,0 24,-10.7216 24,-24 0,-13.27853 -10.72147,-24.00007 -24,-24.00007 z m 0,9.00004 c 8.26059,0 15,6.73943 15,15.00003 0,8.2605 -6.7394,15 -15,15 -8.2606,0 -15,-6.7395 -15,-15 0,-8.2606 6.73941,-15.00003 15,-15.00003 z m 0,4 c -6.09883,0 -11,4.90123 -11,11.00003 0,6.0988 4.90118,11 11,11 6.09882,0 11,-4.9012 11,-11 0,-6.0988 -4.90117,-11.00003 -11,-11.00003 z" fill-opacity="1" stroke="none" marker="none" visibility="visible" display="inline" overflow="visible"></path></g></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Fajr) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Fajr</title><g><path d="M50,37H31.43l-.06-.36a15.89,15.89,0,0,1-.34-3A14.59,14.59,0,0,1,40,20a1,1,0,0,0,0-1.86A15.45,15.45,0,0,0,34.32,17c-8.82,0-16,7.47-16,16.65a16.79,16.79,0,0,0,.35,3.22l0,.13H8a1,1,0,0,0,0,2H50a1,1,0,0,0,0-2ZM20.72,37l-.08-.47a14.9,14.9,0,0,1-.32-2.88c0-8.08,6.28-14.65,14-14.65a12.13,12.13,0,0,1,2.68.31,16.75,16.75,0,0,0-8,14.31A17.83,17.83,0,0,0,29.4,37v0Z"></path></g></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Sunrise) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Sunrise</title><g><path d="M52,42H44s0,0,0,0c0-8.58-6.73-15.56-15-15.56S14,33.38,14,42c0,0,0,0,0,0H6a1,1,0,0,0,0,2H52a1,1,0,0,0,0-2ZM42,42H16v0c0-7.48,5.83-13.56,13-13.56S42,34.48,42,42Z"></path><path d="M29,22.16a1,1,0,0,0,1-1V17a1,1,0,0,0-2,0v4.16A1,1,0,0,0,29,22.16Z"></path><path d="M43.14,28.25a1,1,0,0,0,.72-.31L46.69,25a1,1,0,0,0-1.44-1.39l-2.83,2.94a1,1,0,0,0,.72,1.69Z"></path><path d="M14.14,27.95a1,1,0,1,0,1.44-1.39l-2.83-2.94A1,1,0,0,0,11.31,25Z"></path></g></svg>
 	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Dhuhr) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Dhuhr</title><path d="M29,14.58A14.42,14.42,0,1,0,43.42,29,14.43,14.43,0,0,0,29,14.58Zm0,26.83A12.42,12.42,0,1,1,41.42,29,12.43,12.43,0,0,1,29,41.42Z"></path><path d="M9.83,28H6a1,1,0,0,0,0,2H9.83a1,1,0,0,0,0-2Z"></path><path d="M52,28H48.17a1,1,0,0,0,0,2H52a1,1,0,0,0,0-2Z"></path><path d="M29,10.83a1,1,0,0,0,1-1V6a1,1,0,0,0-2,0V9.83A1,1,0,0,0,29,10.83Z"></path><path d="M29,47.17a1,1,0,0,0-1,1V52a1,1,0,0,0,2,0V48.17A1,1,0,0,0,29,47.17Z"></path><path d="M44.56,12l-2.71,2.71a1,1,0,1,0,1.41,1.41L46,13.44A1,1,0,0,0,44.56,12Z"></path><path d="M14.74,41.85,12,44.56A1,1,0,1,0,13.44,46l2.71-2.71a1,1,0,0,0-1.41-1.41Z"></path><path d="M43.26,41.85a1,1,0,0,0-1.41,1.41L44.56,46A1,1,0,0,0,46,44.56Z"></path><path d="M14.74,16.15a1,1,0,0,0,1.41-1.41L13.44,12A1,1,0,0,0,12,13.44Z"></path></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Asr) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Asr</title><g data-name="Full Moon"><path d="M29,12A17,17,0,1,0,46,29,17,17,0,0,0,29,12Zm0,32A15,15,0,1,1,44,29,15,15,0,0,1,29,44Z"></path></g></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Sunset) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Maghrib</title><g><path d="M52,42H44s0,0,0-.07C44,33.15,37.27,26,29,26S14,33.15,14,41.93c0,0,0,0,0,.07H6a1,1,0,0,0,0,2H52a1,1,0,0,0,0-2ZM42,42H16v-.07C16,34.25,21.83,28,29,28s13,6.25,13,13.93Z"></path></g></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Maghrib) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Maghrib</title><g><path d="M52,42H44s0,0,0-.07C44,33.15,37.27,26,29,26S14,33.15,14,41.93c0,0,0,0,0,.07H6a1,1,0,0,0,0,2H52a1,1,0,0,0,0-2ZM42,42H16v-.07C16,34.25,21.83,28,29,28s13,6.25,13,13.93Z"></path></g></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Isha) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Isha</title><g><path d="M39.86,42.07a14.08,14.08,0,0,1,0-26.13,1,1,0,0,0,0-1.86A15.43,15.43,0,0,0,34.24,13a16,16,0,0,0,0,32,15.43,15.43,0,0,0,5.63-1.07,1,1,0,0,0,0-1.86ZM34.24,43a14,14,0,0,1,0-28,13.22,13.22,0,0,1,2.52.24,16.1,16.1,0,0,0,0,27.51A13.22,13.22,0,0,1,34.24,43Z"></path></g></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Qiyam) {
	                    %>
	                    <svg xmlns:x="http://ns.adobe.com/Extensibility/1.0/" xmlns:i="http://ns.adobe.com/AdobeIllustrator/10.0/" xmlns:graph="http://ns.adobe.com/Graphs/1.0/" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 58 58" style="enable-background:new 0 0 58 58;" xml:space="preserve"><switch><foreignObject requiredExtensions="http://ns.adobe.com/AdobeIllustrator/10.0/" x="0" y="0" width="1" height="1"></foreignObject><g i:extraneous="self"><g><path d="M46,29c0-9-7.1-16.4-16-16.9V12h-1h-1v0.1C19.1,12.6,12,20,12,29s7.1,16.4,16,16.9V46h1h1v-0.1C38.9,45.4,46,38,46,29z      M30,44V14c7.8,0.5,14,7,14,15S37.8,43.5,30,44z"></path></g></g></switch></svg>
	                    <%
	                    	} else if (prayer.getType() == PrayEvent.Type.Tahajjud) {
	                    %>
	                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 58" x="0px" y="0px"><title>PrayEvent.Type.Tahajjud</title><g data-name="Fog, Moon"><path d="M33.14,43.36H14.55a.73.73,0,1,1,0-1.45H33.14a.73.73,0,1,1,0,1.45Z"></path><path d="M38.34,39.73H16a.73.73,0,1,1,0-1.45H38.34a.73.73,0,1,1,0,1.45Z"></path><path d="M35.37,36.09H13.06a.73.73,0,1,1,0-1.45H35.37a.73.73,0,1,1,0,1.45Z"></path><path d="M39.83,47H17.52a.73.73,0,1,1,0-1.45H39.83a.73.73,0,1,1,0,1.45Z"></path><path d="M40.57,32.45H18.27a.73.73,0,1,1,0-1.45H40.57a.73.73,0,1,1,0,1.45Z"></path><path d="M15.07,33a13.62,13.62,0,0,1-1.4-6A14.19,14.19,0,0,1,28,13a14.37,14.37,0,0,1,2.64.25,16,16,0,0,0-8,13.75,15.37,15.37,0,0,0,.13,2h2a13.4,13.4,0,0,1-.15-2,14.09,14.09,0,0,1,9.21-13.06,1,1,0,0,0,0-1.87A16.57,16.57,0,0,0,28,11,16.19,16.19,0,0,0,11.67,27a15.61,15.61,0,0,0,1.2,6Z"></path></g></svg>
	                    <%
	                    	}
	                    %>
	                </div>
	            </div>
	            <%
	            	if (activePrayer) {
               	%>
               		<div class="events__item__desc__text"><%=prayer.getStartedTimeAgo(now)%></div>
              	<%
                  		if (prayer.getType().getRecommendedFraction() < 1.0 && prayer.withinRecommendedTime(now)) {
                %>
                   	<div class="events__item__desc__text">Recommended time ends <%=prayer.getRecommendedEndTimeLeft(now)%></div>
                <%
                   		} else {
                %>
                    <div class="events__item__desc__text">Time ends <%=prayer.getNextEventTimeLeft(now)%></div>
                <%
                		}
                    }
	            	if (prayer.isPrevEvent(now) != null && prayer.isPrevEvent(now))  {
	            %>
	               	<div class="events__item__desc__text"><%=prayer.getEndedTimeAgo(now)%></div>
	            <%
	               	}
                	if (prayer.isNextEvent(now) != null && prayer.isNextEvent(now))  {
                %>
                   	<div class="events__item__desc__highlight">Starts in <%=PrayEvent.getMinutesToTime(prayer.getPrevEvent().getNextEventMinutesLeft(now))%></div>
                <%
                   	}
	            	if (prayer.getType() == PrayEvent.Type.Fajr) {
	            		int dayOfYear = nowCal.get(Calendar.DAY_OF_YEAR);
	            		int quranPage = 0;
	        			try {
	        				quranPage = (int) Math.floor(604. / 366. * dayOfYear);
	        				if (quranPage > 604) {
	        					quranPage = 1;
	        				}
	        			} catch (Exception e) {
	        			}

	            %>
	            	<div class="events__item__desc__text"><a href="http://quranunlocked.com/pg/<%=quranPage%>">Today's Quran Reading: Page <%=quranPage%></a></div>
	            	<div class="events__item__desc__text">Fast today <%=PrayEvent.getFastingDuration(fajr, maghrib)%> long</div>
                <%
	            	}
                	if (!activePrayer && prayer.getType() == PrayEvent.Type.Suhoor && prayer.isWithin(now))  {
                %>
                   	<div class="events__item__desc__highlight">Time ends <%=prayer.getNextEventTimeLeft(now)%></div>
                <%
                   	}
              	%>
            </li>
			<%
				}
			%>
		</ul>
		
		<div class="pl-3 pr-3">
					
			<p class="mt-3 mb-3">
				<div class="text-center">
					<a role="button" class="btn btn-primary webcal-button" href=""><i class="far fa-calendar-plus"></i>&nbsp; Add to Apple Calendar</a>
				</div>
				<p class="mt-3 text-center alert alert-success" role="alert" style="overflow-wrap: break-word; text-overflow: ellipsis; overflow: hidden;"><small>
					<strong>OR</strong><br>
					Copy the URL below to subscribe into other calendars:<br>
					<a id="ics-link" href=""></a>
				</small></p>
				<p class="text-center alert alert-success" role="alert" style="overflow-wrap: break-word;"><small>
					<a target="_blank" href="https://support.google.com/calendar/answer/37100?hl=en&ref_topic=3417970"><i class="fas fa-question-circle"></i> How to add prayer times to <strong>Google Calendar</strong> using the above URL</a>
				</small></p>
			</p>
	
			<h1>Prayer Webcal</h1>
			<h2>World Prayer Times Alarm Notification Subscription Calendar</h2>
			<ul>
				<!--<li><a href="/locations.html">Global times</a> for the five daily Muslim Sunni and Shia prayers</li>-->
				<li>Prayer calendars can be downloaded or subscribed to as an <strong>iCal</strong> feed and imported to your 
				iPhone, Apple, Google Calendar, MS Outlook, or Apple Mac calendars</li>
			</ul>

			<h2>Unlock the Quran!</h2>
			<p><a href="https://quranunlocked.com">Read the Quran daily and hold fast the Message of God.</a></p>
			<p><a href="https://www.facebook.com/prayerwebcal">Prayerwebcal on Facebook</a></p>
						
	</div>
				
	</main>
    <script type="text/javascript">
        var ics_path = window.location.protocol + "//" + window.location.host + '/<%=cfg.getICSPath()%>'

        window.addEventListener("load", (event) => 
        {
            $(".webcal-button").attr("href", ics_path.replace("https", "webcal").replace("http", "webcal"));
            $("#ics-link").attr("href", ics_path).html(ics_path);
        });
        
    </script>
    <script src="/res/jquery-3.3.1.slim.min.js"></script>
    <script src="/res/popper.min.js"></script>
    <script src="/res/bootstrap.min.js"></script>
	<script type="text/javascript">
		PullToRefresh.init({
			  mainElement: '.events',
			  onRefresh: function (done) {
			    setTimeout(function () {
			      location.reload();
			    }, 500);
			  }
		});
	</script>
	
</body>
</html>
