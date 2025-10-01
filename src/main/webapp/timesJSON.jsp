<%@page import="java.util.Iterator"%><%@page 
	import="java.time.ZoneOffset"%><%@page
 	import="java.util.ArrayList"%><%@page import="java.util.List"%><%@page import="java.io.IOException"%><%@page
	import="praytimes.PrayEvent"%><%@page import="java.time.ZoneId"%><%@page import="java.time.OffsetDateTime"%><%@page
	import="praytimes.Config"%><%@page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%><%
	
	response.setHeader("Cache-Control", "public");
	Config cfg = new Config(request);
	OffsetDateTime today = OffsetDateTime.now(ZoneId.of("UTC"));
	if (request.getParameter("when") != null)
		today = OffsetDateTime.parse(request.getParameter("when"));
	today = today.withOffsetSameLocal(ZoneOffset.ofTotalSeconds(cfg.getTZDSTOffset() * 60));
	today = today.plusMinutes(cfg.getTZDSTOffset());

	OffsetDateTime yesterday = today.minusDays(1);
	OffsetDateTime tomorrow = today.plusDays(1);
	List<String> todayTimes = cfg.getPrayerTimes(today);
	List<String> yesterdayTimes = cfg.getPrayerTimes(yesterday);
	List<String> tomorrowTimes = cfg.getPrayerTimes(tomorrow);
	List<PrayEvent> prayers = new ArrayList<PrayEvent>();
	try {
		PrayEvent prevSunset = new PrayEvent(cfg, PrayEvent.Type.Sunset, yesterday,
				yesterdayTimes.get(PrayEvent.Type.Sunset.ordinal()));
		PrayEvent prevMaghrib = new PrayEvent(cfg, PrayEvent.Type.Maghrib, yesterday,
				yesterdayTimes.get(PrayEvent.Type.Maghrib.ordinal()));

		PrayEvent fajr = new PrayEvent(cfg, PrayEvent.Type.Fajr, today, todayTimes.get(PrayEvent.Type.Fajr.ordinal()));
		PrayEvent suhoor = PrayEvent.getSuhoorEvent(today, fajr);
		PrayEvent sunrise = new PrayEvent(cfg, PrayEvent.Type.Sunrise, today,
				todayTimes.get(PrayEvent.Type.Sunrise.ordinal()));
		PrayEvent afterSunrise = new PrayEvent(cfg, PrayEvent.Type.EndingEvent, today,
				sunrise.getStartTime().plusMinutes(20));
		PrayEvent dhuhr = new PrayEvent(cfg, PrayEvent.Type.Dhuhr, today, todayTimes.get(PrayEvent.Type.Dhuhr.ordinal()));
		PrayEvent asr = new PrayEvent(cfg, PrayEvent.Type.Asr, today, todayTimes.get(PrayEvent.Type.Asr.ordinal()));
		PrayEvent sunset = new PrayEvent(cfg, PrayEvent.Type.Sunset, today,
				todayTimes.get(PrayEvent.Type.Sunset.ordinal()));
		PrayEvent maghrib = new PrayEvent(cfg, PrayEvent.Type.Maghrib, today,
				todayTimes.get(PrayEvent.Type.Maghrib.ordinal()));
		PrayEvent isha = new PrayEvent(cfg, PrayEvent.Type.Isha, today, todayTimes.get(PrayEvent.Type.Isha.ordinal()));
		PrayEvent qiyam = PrayEvent.getQiyamEvent(today, prevSunset, fajr, sunrise);
		PrayEvent tahajjud = PrayEvent.getTahajjudEvent(today, prevSunset, fajr, sunrise);

		PrayEvent nextFajr = new PrayEvent(cfg, PrayEvent.Type.Fajr, tomorrow,
				tomorrowTimes.get(PrayEvent.Type.Fajr.ordinal()));
		PrayEvent nextSunrise = new PrayEvent(cfg, PrayEvent.Type.Sunrise, tomorrow,
				tomorrowTimes.get(PrayEvent.Type.Sunrise.ordinal()));
		PrayEvent nextQiyam = PrayEvent.getQiyamEvent(tomorrow, sunset, nextFajr, nextSunrise);

		prayers.add(qiyam.setNextEvent(tahajjud));
		prayers.add(tahajjud.setPrevEvent(qiyam).setNextEvent(suhoor));
		prayers.add(suhoor.setPrevEvent(tahajjud).setNextEvent(fajr));
		prayers.add(fajr.setPrevEvent(suhoor).setNextEvent(sunrise));
		prayers.add(sunrise.setPrevEvent(fajr).setNextEvent(afterSunrise));
		prayers.add(afterSunrise.setPrevEvent(sunrise).setNextEvent(dhuhr));
		prayers.add(dhuhr.setPrevEvent(afterSunrise).setNextEvent(asr));
		prayers.add(asr.setPrevEvent(dhuhr).setNextEvent(sunset));
		prayers.add(sunset.setPrevEvent(asr).setNextEvent(maghrib));
		prayers.add(maghrib.setPrevEvent(sunset).setNextEvent(isha));
		prayers.add(isha.setPrevEvent(maghrib).setNextEvent(nextQiyam));

	} catch (Exception e) {
		throw new IOException(e);
	}
%>[ 
{ 
	"@context": "http://schema.org", 
	"@type": "EventSeries", 
	"@id": "https://prayerwebcal.dsultan.com/prayers", 
	"name": "Islamic Prayer Times for <%=cfg.getLocation()%> at <%=today.format(PrayEvent.DATE) + " " + today.format(PrayEvent.TIME).toLowerCase()%>",
	"location": { 
		"@type": "Place", 
		"geo": { 
			"@type": "GeoCoordinates",
			"latitude": "<%=cfg.getLatitude()%>", 
			"longitude": "<%=cfg.getLongitude()%>"
		}, 
		"address": "<%=cfg.getLocation()%>", 
		"name": "<%=cfg.getLocation()%>"
	}
},
<%
	for (Iterator<PrayEvent> i = prayers.iterator(); i.hasNext(); ) {
		PrayEvent prayer = i.next();
		if (prayer.getType() == PrayEvent.Type.EndingEvent || prayer.getType() == PrayEvent.Type.InvalidEvent)
			continue;
%>
{ 
	"@context": "http://schema.org", 
	"@type": "Event", 
	"location": { 
		"@type": "Place", 
		"geo": { 
			"@type": "GeoCoordinates",
			"latitude": "<%=cfg.getLatitude()%>", 
			"longitude": "<%=cfg.getLongitude()%>"
		}, 
		"address": "<%=cfg.getLocation()%>", 
		"name": "<%=cfg.getLocation()%>"
	}, 
	"name": "<%=prayer.getName()%> at <%=cfg.getLocation()%>", 
	"description": "<%=cfg.toStringNoDefaults()%>", 
	"startDate": "<%=prayer.getStartTime()%>", 
	"endDate": "<%=prayer.getEndTime()%>"
}<%=i.hasNext() ? "," : ""%>
<%
	}
%>
]
