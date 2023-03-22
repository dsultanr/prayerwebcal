package praytimes;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URI;
import java.net.URLEncoder;
import java.sql.Date;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.fortuna.ical4j.model.component.VEvent;
import net.fortuna.ical4j.model.property.CalScale;
import net.fortuna.ical4j.model.property.Categories;
import net.fortuna.ical4j.model.property.Clazz;
import net.fortuna.ical4j.model.property.Method;
import net.fortuna.ical4j.model.property.ProdId;
import net.fortuna.ical4j.model.property.RRule;
import net.fortuna.ical4j.model.property.Transp;
import net.fortuna.ical4j.model.property.Url;
import net.fortuna.ical4j.model.property.Version;
import net.fortuna.ical4j.model.property.XProperty;

public class ICSServlet extends HttpServlet {

	private static final long serialVersionUID = -1L;

	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
		trackPageView(request, response);
		Config cfg;
		try {
			cfg = new Config(request);
			if (cfg.getLatitude() == 0 && cfg.getLongitude() == 0) {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid request");
				return;
			}
		} catch (Exception e) {
			throw new IOException(e);
		}
		net.fortuna.ical4j.model.Calendar ics = generateICS(cfg);
		response.setContentType("text/calendar; charset=UTF-8");
		response.setHeader("Content-Disposition", "attachment; filename=\"" + Config.clean(cfg.getLocation()) + ".ics\"");
		PrintWriter out = response.getWriter();
		out.write(ics.toString());
	}

	public net.fortuna.ical4j.model.Calendar generateICS(Config cfg) throws IOException {
		net.fortuna.ical4j.model.Calendar ics = new net.fortuna.ical4j.model.Calendar();
		ics.getProperties().add(new ProdId("-//vegaSTONE//Prayer Webcal 2.0//EN"));
		ics.getProperties().add(Version.VERSION_2_0);
		ics.getProperties().add(CalScale.GREGORIAN);
		ics.getProperties().add(Method.PUBLISH);
		StringBuilder s = new StringBuilder("Prayer Times for " + cfg.getLocation());
		ics.getProperties().add(new XProperty("X-WR-CALNAME", s.toString()));
		s.append(";\n ");
		s.append("; Location: ").append(cfg.getLatitude()).append(", ").append(cfg.getLongitude()).append('\n');
		if (cfg.isTimeZone())
			s.append("; Timezone: ").append(cfg.getTimeZone()).append("").append('\n');
		else
			s.append("; Timezone Offset: ").append(cfg.getTZDSTOffset()).append("").append('\n');
		s.append("; Config: ").append(cfg.toStringNoDefaults());
		ics.getProperties().add(new XProperty("X-WR-CALDESC", s.toString()));

		int n = 1;
		int quranPage = 0;
                CalendarIterator calendarIterator = new CalendarIterator();
                calendarIterator.DAYS_MAX = cfg.getNumberOfMonthsSetting() * 30;
		for (Calendar date : calendarIterator) {
			OffsetDateTime today = date.toInstant().atZone(ZoneId.systemDefault()).toOffsetDateTime();

			try {
				quranPage = (int) Math.floor(604. / 366. * n++);
				if (quranPage > 604) {
					n = 1;
					quranPage = 1;
				}
				// ics.getComponents().add(getDailyQuranEvent(quranPage, today));
			} catch (Exception e) {
			}

			OffsetDateTime yesterday = today.minusDays(1);
			OffsetDateTime tomorrow = today.plusDays(1);
			List<String> todayTimes = cfg.getPrayerTimes(today);
			List<String> yesterdayTimes = cfg.getPrayerTimes(yesterday);
			List<String> tomorrowTimes = cfg.getPrayerTimes(tomorrow);
			List<PrayEvent> prayers = new ArrayList<PrayEvent>();
			try {
				PrayEvent prevSunset = new PrayEvent(cfg, PrayEvent.Type.Sunset, yesterday,
						yesterdayTimes.get(PrayEvent.Type.Sunset.ordinal()));

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
			for (PrayEvent prayer : prayers) {
				if (prayer.getType() == PrayEvent.Type.Sunset && cfg.getSunsetAlert() == 0)
					continue;
				if (prayer.getType() == PrayEvent.Type.Sunrise && cfg.getSunriseAlert() == 0)
					continue;
				if (prayer.getType() == PrayEvent.Type.Qiyam && cfg.getQiyamAlert() == 0)
					continue;
				if (prayer.getType() == PrayEvent.Type.Tahajjud && cfg.getTahajjudAlert() == 0)
					continue;
				if (prayer.getType() == PrayEvent.Type.Suhoor && cfg.getSuhoorAlert() == 0)
					continue;
				if (prayer.getNextEvent() != null && prayer.getStartTime().isEqual(prayer.getNextEvent().getStartTime()))
					continue;
				if (prayer.getType() == PrayEvent.Type.EndingEvent || prayer.getType() == PrayEvent.Type.InvalidEvent)
					continue;
				try {
					ics.getComponents().add(prayer.toEvent(quranPage));
				} catch (Exception e) {
					throw new IOException(e);
				}
			}

		}
		s.append("; Prayer Webcal - https://prayerwebcal.dsultan.com\n");
		return ics;
	}

	public VEvent getDailyQuranEvent(int pg, OffsetDateTime today) throws Exception {
		String eventName = "📖 Daily Quran";
		VEvent event = new VEvent(new net.fortuna.ical4j.model.Date(Date.from(today.toInstant())), eventName);
		event.getProperties().add(new XProperty("UID", today.format(PrayEvent.DATEID) + "-Quran@prayerwebcal.dsultan.com"));
		event.getProperties().add(new Categories("Todo"));
		event.getProperties().add(new XProperty("X-GOOGLE-CALENDAR-CONTENT-TITLE", eventName));
		event.getProperties().add(new XProperty("X-MICROSOFT-CDO-BUSYSTATUS", "FREE"));
		event.getProperties().add(new Url(new URI("http://quranunlocked.com/pg/" + pg)));
		event.getStartDate().setUtc(true);
		event.getEndDate().setUtc(true);
		event.getProperties().add(new RRule("FREQ=YEARLY"));
		event.getProperties().add(Clazz.PUBLIC);
		event.getProperties().add(Transp.TRANSPARENT);
		return event;
	}

	// Copyright 2009 Google Inc. All Rights Reserved.
	private static final String GA_ACCOUNT = "UA-10540377-3";

	private void trackPageView(HttpServletRequest request, HttpServletResponse response) throws IOException {
		String utmac = GA_ACCOUNT;
		// String utmn = Integer.toString((int) (Math.random() * 0x7fffffff));
		String utmdebug = null;
		String guid = "ON";
		String utmp = null;
		String referer = request.getHeader("referer");
		String query = request.getQueryString();
		String path = request.getRequestURI();
		if (referer == null || "".equals(referer)) {
			referer = "-";
		}
		if (path != null) {
			if (query != null) {
				path += "?" + query;
			}
			utmp = URLEncoder.encode(path, "UTF-8");
		}
		String utmr = URLEncoder.encode(referer, "UTF-8");
		new TrackGoogleAnalyticsPageView(request, response, utmr, utmp, utmac, utmdebug, guid);
	}

}
