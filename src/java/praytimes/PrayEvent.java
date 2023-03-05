package praytimes;

import java.net.URI;
import java.sql.Date;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.logging.Logger;

import org.apache.commons.lang3.StringUtils;
import praytimes.Config.MidnightMethodOption;

import net.fortuna.ical4j.model.Dur;
import net.fortuna.ical4j.model.component.VAlarm;
import net.fortuna.ical4j.model.component.VEvent;
import net.fortuna.ical4j.model.property.Action;
import net.fortuna.ical4j.model.property.Categories;
import net.fortuna.ical4j.model.property.Clazz;
import net.fortuna.ical4j.model.property.Description;
import net.fortuna.ical4j.model.property.Location;
import net.fortuna.ical4j.model.property.RRule;
import net.fortuna.ical4j.model.property.Transp;
import net.fortuna.ical4j.model.property.Url;
import net.fortuna.ical4j.model.property.XProperty;

public class PrayEvent implements Comparable<PrayEvent> {

	public enum Event {
		NonPrayer, OptionalPrayer, MandatoryPrayer
	}

	public enum Type {

		Fajr(Event.MandatoryPrayer, true, 0.5), Sunrise(Event.NonPrayer, true, 0.0, "🌅"), Dhuhr(Event.MandatoryPrayer, true,
				0.5), Asr(Event.MandatoryPrayer, true, 0.5), Sunset(Event.NonPrayer, false, 0.0, "🌇"), Maghrib(
						Event.MandatoryPrayer, true, 0.5), Isha(Event.MandatoryPrayer, true, 1.0), Qiyam(Event.OptionalPrayer, true,
								1.0), Tahajjud(Event.OptionalPrayer, true, 1.0), Suhoor(Event.NonPrayer, false,
										1.0), EndingEvent(Event.NonPrayer, true, 0.0), InvalidEvent(Event.NonPrayer, true, 0.0);

		private Event eventType;
		private boolean endTime;
		private double recommendedFraction;
		private String emoji = null;

		Type(Event eventType, boolean endingTime) {
			this(eventType, endingTime, 0.0);
		}

		Type(Event eventType, boolean endTime, double recommendedFraction) {
			this.eventType = eventType;
			this.endTime = endTime;
			this.recommendedFraction = recommendedFraction;
		}

		Type(Event eventType, boolean endTime, double recommendedFraction, String emoji) {
			this.eventType = eventType;
			this.endTime = endTime;
			this.recommendedFraction = recommendedFraction;
			this.emoji = emoji;
		}

		public Event getEventType() {
			return eventType;
		}

		public boolean isPrayer() {
			return eventType == Event.OptionalPrayer || eventType == Event.MandatoryPrayer;
		}

		public boolean isEndTime() {
			return endTime;
		}

		public double getRecommendedFraction() {
			return recommendedFraction;
		}

		public String getEmojiName() {
			if (emoji != null)
				return emoji + " " + name();
			return name();
		}

	};

	private static Logger log = Logger.getLogger(PrayEvent.class.getName());

	public static final SimpleDateFormat ISO_DATE_OLD = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'");
	public static final DateTimeFormatter ISO_DATE = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'");
	public static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("MMMM d, yyyy");
	public static final DateTimeFormatter DATEID = DateTimeFormatter.ofPattern("DDD");
	public static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("h:mm a");
	public static final DateTimeFormatter TIME24 = DateTimeFormatter.ofPattern("HH:mm");
	public static final DateTimeFormatter DATETIME = DateTimeFormatter.ofPattern("MMMM d, yyyy h:mm a");

	private Config cfg;
	private Type type;
	private OffsetDateTime startTime;
	private PrayEvent prevEvent;
	private PrayEvent nextEvent;
	boolean reminder = true;

	public PrayEvent(Config cfg, Type type, OffsetDateTime now, String startTimeString) throws ParseException {
		this.cfg = cfg;
		this.type = type;
		try {
			String[] t = startTimeString.split(":");
			LocalDateTime hm = LocalDateTime.now(ZoneId.of("UTC")).withHour(Integer.parseInt(t[0]))
					.withMinute(Integer.parseInt(t[1]));
			hm = hm.plusMinutes(cfg.getTZDSTOffset());
			startTime = now.withYear(now.getYear()).withMonth(now.getMonthValue()).withDayOfMonth(now.getDayOfMonth())
					.withHour(hm.getHour()).withMinute(hm.getMinute());
		} catch (Exception e) {
			this.type = Type.InvalidEvent;
			startTime = now;
			log.fine(type + " time=" + startTimeString + ", unable to calc " + type + " time using cfg: " + cfg);
		}
	}

	public PrayEvent(Config config, Type type, OffsetDateTime now, OffsetDateTime startTime) throws ParseException {
		this.cfg = config;
		this.type = type;
		this.startTime = startTime;
	}

	public Config getConfig() {
		return cfg;
	}

	public String getName() {
            String prayEventName = type.name();
            if (prayEventName.equals("Dhuhr") && getDayOfWeek() == "FRIDAY" && cfg.getJumaahSetting() == 1) {
                return "Jumaah";
            } else {
                return prayEventName;
            }
	
	}

	public Type getType() {
		return type;
	}

	public OffsetDateTime getStartTime() {
		return startTime;
	}

	public String getDayOfWeek() {
		return startTime.getDayOfWeek().name();
	}

	public OffsetDateTime getEndTime() {
		if (nextEvent != null)
			return nextEvent.getStartTime();
		else
			throw new RuntimeException("No next event defined for " + this);
	}

	public OffsetDateTime getActualEndTime() {
		return getNextEndingEvent().getStartTime().minusMinutes(1);
	}

	public PrayEvent getPrevEvent() {
		return prevEvent;
	}

	public PrayEvent setPrevEvent(PrayEvent event) {
		this.prevEvent = event;
		return this;
	}

	public PrayEvent getPrevPrayer() {
		if (!prevEvent.type.isPrayer())
			return prevEvent.getPrevEvent();
		return prevEvent;
	}

	public PrayEvent getNextEvent() {
		return nextEvent;
	}

	public PrayEvent setNextEvent(PrayEvent event) {
		this.nextEvent = event;
		return this;
	}

	public PrayEvent getNextPrayer() {
		if (nextEvent != null) {
			if (!nextEvent.getType().isPrayer())
				return nextEvent.getNextEvent();
			else
				throw new RuntimeException("No next prayer defined for " + this);
		} else
			throw new RuntimeException("No next event defined for " + this);

	}

	public PrayEvent getNextEndingEvent() {
		if (nextEvent != null) {
			if (!nextEvent.getType().isEndTime())
				return nextEvent.getNextEvent();
			else
				return nextEvent;
		} else
			throw new RuntimeException("No next event defined for " + this);
	}

	public String getFormattedTimeNow(OffsetDateTime now) {
		return now.format(DATETIME);
	}

	public String getFormattedDate() {
		return startTime.format(DATE);
	}

	public String getFormattedTime() {
		return startTime.format(TIME).toLowerCase();
	}

	public void setReminder(boolean reminder) {
		this.reminder = reminder;
	}

	public boolean isActive(OffsetDateTime now) {
		return now.isEqual(startTime) || (now.isAfter(startTime) && now.isBefore(getNextEndingEvent().getStartTime()));
	}

	public boolean isWithin(OffsetDateTime now) {
		return now.isEqual(startTime) || (now.isAfter(startTime) && now.isBefore(getNextEndingEvent().getStartTime()));
	}

	public Boolean isPrevEvent(OffsetDateTime now) {
		if (nextEvent != null)
			return (now.isEqual(nextEvent.getStartTime()) || now.isAfter(nextEvent.getStartTime()))
					&& now.isBefore(nextEvent.getEndTime());
		else
                    return null;
//			throw new RuntimeException("No next event defined for " + this);
	}

	public Boolean isNextEvent(OffsetDateTime now) {
		if (getPrevPrayer() != null && prevEvent != null)
			return now.isBefore(startTime)
					&& (now.isEqual(getPrevPrayer().getStartTime()) || now.isAfter(getPrevPrayer().getStartTime())
							|| now.isEqual(prevEvent.getStartTime()) || now.isAfter(prevEvent.getStartTime()));
		else
                    return null;
//			throw new RuntimeException("No prev prayer defined for " + this);
	}

	public boolean withinRecommendedTime(OffsetDateTime now) {
		if (isActive(now))
			return now.isBefore(getRecommendedEndTime());
		return false;
	}

	public String getRecommendedEndTimeLeft(OffsetDateTime now) {
		if (getRecommendedMinutesLeft(now) <= 10)
			return "soon";
		else if (getRecommendedMinutesLeft(now) <= 20)
			return "in " + getMinutesToTime(getRecommendedMinutesLeft(now));
		return "at " + now.plusMinutes(getRecommendedMinutesLeft(now)).format(TIME).toLowerCase();
	}

	public String getNextEventTimeLeft(OffsetDateTime now) {
		if (getNextEventMinutesLeft(now) <= 10)
			return "soon";
		else if (getNextEventMinutesLeft(now) <= 20)
			return "in " + getMinutesToTime(getNextEventMinutesLeft(now));
		return "at " + now.plusMinutes(getNextEventMinutesLeft(now)).format(TIME).toLowerCase();
	}

	public String getStartedTimeAgo(OffsetDateTime now) {
		long minutes = Math.abs(now.toEpochSecond() - startTime.toEpochSecond()) / 60;
		if (minutes > 10)
			return "Started " + getMinutesToTime(minutes) + " ago";
		return "Just started";
	}

	public String getEndedTimeAgo(OffsetDateTime now) {
		long minutes = Math.abs(now.toEpochSecond() - getEndTime().toEpochSecond()) / 60;
		if (minutes > 10)
			return "Ended " + getMinutesToTime(minutes) + " ago";
		return "Just ended";
	}

	public long getRecommendedMinutesLeft(OffsetDateTime now) {
		return Math.abs(now.toEpochSecond() - getRecommendedEndTime().toEpochSecond()) / 60;
	}

	public long getNextEventMinutesLeft(OffsetDateTime now) {
		if (nextEvent != null)
			return Math.abs(now.toEpochSecond() - nextEvent.getStartTime().toEpochSecond()) / 60;
		else
			throw new RuntimeException("No next event defined for " + this);
	}

	public long getNextEndingEventMinutesLeft(OffsetDateTime now) {
		return Math.abs(now.toEpochSecond() - getNextEndingEvent().getStartTime().toEpochSecond()) / 60;
	}

	public long getNextPrayerMinutesLeft(OffsetDateTime now) {
		return Math.abs(now.toEpochSecond() - getNextPrayer().getStartTime().toEpochSecond()) / 60;
	}

	private OffsetDateTime getRecommendedEndTime() {
		long midLength = (long) ((Math.abs(startTime.toEpochSecond() - getNextEndingEvent().getStartTime().toEpochSecond()) / 60)
				* type.getRecommendedFraction());
		return startTime.plusMinutes(midLength);
	}

	public String getFriendlyConfig() {
		StringBuilder str = new StringBuilder();
		if (type == Type.Fajr) {
			if (cfg.getHighAltitudeMethod() == Config.HighAltitudeMethodOption.AngleBased.ordinal())
				str.append(cfg.getFajrValue() + "\u00b0");
			else if (cfg.getHighAltitudeMethod() == Config.HighAltitudeMethodOption.OneSeventh.ordinal())
				str.append("6/7th");
			else if (cfg.getHighAltitudeMethod() == Config.HighAltitudeMethodOption.Midnight.ordinal())
				str.append("\u00bd");
			if (cfg.getFajrOffset() > 0)
				str.append("+" + cfg.getFajrOffset());
		} else if (type == Type.Maghrib) {
			if (cfg.getMaghribMethod() == Config.NightMethodOption.AngleBased.ordinal())
				str.append(cfg.getMaghribValue() + "\u00b0");
			else
				str.append("+" + cfg.getMaghribValue().intValue());
			if (cfg.getMaghribOffset() > 0)
				str.append("+" + cfg.getMaghribOffset());
		} else if (type == Type.Isha) {
			if (cfg.getIshaMethod() == Config.NightMethodOption.AngleBased.ordinal()) {
				if (cfg.getHighAltitudeMethod() == Config.HighAltitudeMethodOption.AngleBased.ordinal())
					str.append(cfg.getIshaValue() + "\u00b0");
				else if (cfg.getHighAltitudeMethod() == Config.HighAltitudeMethodOption.OneSeventh.ordinal())
					str.append("2/7th");
				else if (cfg.getHighAltitudeMethod() == Config.HighAltitudeMethodOption.Midnight.ordinal())
					str.append("\u00bd");
			} else
				str.append("+" + cfg.getIshaValue().intValue());
			if (cfg.getIshaOffset() > 0)
				str.append("+" + cfg.getIshaOffset());
		} else if (type == Type.Dhuhr) {
			str.append("+" + cfg.getDhuhrOffset());
		} else if (type == Type.Asr) {
			if (cfg.getAsrMethod() == Config.AsrMethodOption.EqualToShadowLength.ordinal())
				str.append("x1");
			else
				str.append("x2");
			if (cfg.getAsrOffset() > 0)
				str.append("+" + cfg.getAsrOffset());
		} else if (type == Type.Qiyam) {
			str.append("\u00bd " + (cfg.getMidnightMethod() == Config.MidnightMethodOption.SunsetToFajr.ordinal() ? "sf" : "ss"));
		} else if (type == Type.Tahajjud) {
			str.append("\u2154 " + (cfg.getMidnightMethod() == Config.MidnightMethodOption.SunsetToFajr.ordinal() ? "sf" : "ss"));
		} else if (type == Type.Suhoor) {
			str.append("" + cfg.getSuhoorOffset());
		}
		return StringUtils.trimToEmpty(str.toString());
	}

	public VEvent toEvent(int quranPage) throws Exception {
		LocalDateTime time = startTime.toLocalDateTime().minusMinutes(cfg.getTZDSTOffset());
//		String eventName = type.getEmojiName() + " " + startTime.format(TIME).toLowerCase();
		String eventName = type.getEmojiName();
                LocalDateTime endTime;
                try
                {
                    switch (cfg.getEventEnd()) {
                        case 1:
                            endTime = time.plusMinutes(20);
                            break;
                        case 2:
                            endTime = time.plusMinutes(30);
                            break;
                        case 3:
                            endTime = time.plusMinutes(40);
                            break;
                        case 4:
                            endTime = getRecommendedEndTime().toLocalDateTime().minusMinutes(cfg.getTZDSTOffset());
                            break;
                        default:
                            endTime = time.plusMinutes(20);
                            break;
                    }
                } catch (Exception e)
                {
                    endTime = time.plusMinutes(20);
                }

//                LocalDateTime endTime = getEndTime().toLocalDateTime().minusMinutes(cfg.getTZDSTOffset()).minusMinutes(1);
//		if (type.getEventType() != Event.NonPrayer || type == Type.Suhoor)
//			eventName += " (" + getFriendlyConfig() + ")";
		VEvent event = new VEvent(
                                new net.fortuna.ical4j.model.DateTime(Date.from(time.toInstant(ZoneOffset.UTC))),
				new net.fortuna.ical4j.model.DateTime(Date.from(endTime.toInstant(ZoneOffset.UTC))), 
                                eventName);
		event.getProperties().add(
				new XProperty("UID", startTime.format(DATEID) + "-" + type.name().toUpperCase() + "@prayerwebcal.dsultan.com"));
		event.getProperties().add(new XProperty("X-GOOGLE-CALENDAR-CONTENT-TITLE", eventName));
		event.getProperties().add(new XProperty("X-MICROSOFT-CDO-BUSYSTATUS", "FREE"));
		event.getStartDate().setUtc(true);
		event.getEndDate().setUtc(true);
		try {
			event.getProperties().add(new RRule("FREQ=YEARLY"));
		} catch (ParseException e) {
		}
		event.getProperties().add(new Location(cfg.getLocation()));
		try {
			String description = "";
			if (type == Type.Fajr) {
				event.getProperties().add(new Url(new URI("https://prayerwebcal.dsultan.com" + cfg.getPath())));
				description += "Daily Quran: http://quranunlocked.com/pg/" + quranPage;
			}
			if (type.getEventType() == Event.MandatoryPrayer) {
				event.getProperties().add(new Categories("Prayer"));
				long minutes = Math.abs(startTime.toEpochSecond() - getEndTime().toEpochSecond()) / 60;
				description += "\nDuration: " + getMinutesToTime(minutes);
				if (getRecommendedEndTime().isBefore(getEndTime()))
					description += "\nPreferred End Time: " + getRecommendedEndTime().format(TIME);
			}
			event.getProperties().add(new Description(description));
		} catch (Exception e) {
		}
		event.getProperties().add(Clazz.PUBLIC);
		event.getProperties().add(Transp.TRANSPARENT);
		if (reminder) {
			VAlarm alarm = new VAlarm(new Dur(0, 0, 0, 0));
			alarm.getProperties().add(Action.DISPLAY);
			alarm.getProperties().add(new Description("Time for " + type.toString()));
			event.getAlarms().add(alarm);
		}
		return event;
	}

	public static String getFastingDuration(PrayEvent fajr, PrayEvent maghrib) {
		long duration = Math.abs(fajr.getStartTime().toEpochSecond() - maghrib.getStartTime().toEpochSecond()) / 60;
		return "is " + getMinutesToTime(duration);
	}

	public static PrayEvent getSuhoorEvent(OffsetDateTime now, PrayEvent fajr) throws Exception {
		return new PrayEvent(fajr.getConfig(), Type.Suhoor, now,
				fajr.getStartTime().plusMinutes(fajr.getConfig().getSuhoorOffset()));
	}

	public static PrayEvent getQiyamEvent(OffsetDateTime now, PrayEvent sunset, PrayEvent nextFajr, PrayEvent nextSunrise)
			throws Exception {
		return getNightFraction(Type.Qiyam, now, sunset, nextFajr, nextSunrise, 0.5);
	}

	public static PrayEvent getTahajjudEvent(OffsetDateTime now, PrayEvent sunset, PrayEvent nextFajr, PrayEvent nextSunrise)
			throws Exception {
		return getNightFraction(Type.Tahajjud, now, sunset, nextFajr, nextSunrise, 2. / 3.);
	}

	private static PrayEvent getNightFraction(Type type, OffsetDateTime now, PrayEvent sunset, PrayEvent nextFajr,
			PrayEvent nextSunrise, double fraction) throws Exception {
		Config cfg = sunset.getConfig();
		double lengthOfNight = 0;
		if (cfg.getMidnightMethod() == MidnightMethodOption.SunsetToSunrise.ordinal())
			lengthOfNight = Math.abs(sunset.getStartTime().toEpochSecond() - nextSunrise.getStartTime().toEpochSecond()) / 60;
		else if (cfg.getMidnightMethod() == MidnightMethodOption.SunsetToFajr.ordinal())
			lengthOfNight = Math.abs(sunset.getStartTime().toEpochSecond() - nextFajr.getStartTime().toEpochSecond()) / 60;
		OffsetDateTime fractionStartTime = sunset.getStartTime().plusMinutes(Math.round(lengthOfNight * fraction));
		return new PrayEvent(sunset.getConfig(), type, now, fractionStartTime);
	}

	public static String getMinutesToTime(long totalMinutes) {
		if (totalMinutes < 1)
			return "";
		if (totalMinutes > 59) {
			long minutes = totalMinutes % 60;
			if (minutes < 1)
				return String.format("%d hrs", (int) (totalMinutes / 60));
			return String.format("%d hrs %d min", (int) (totalMinutes / 60), totalMinutes % 60);
		}
		return String.format("%d min", (int) totalMinutes);
	}

	@Override
	public String toString() {
		return type + " " + startTime.format(DATETIME);
	}

	@Override
	public boolean equals(Object other) {
		PrayEvent otherEvent = (PrayEvent) other;
		return type.equals(otherEvent.getType()) && otherEvent.getStartTime().equals(otherEvent.getStartTime());
	}

	@Override
	public int compareTo(PrayEvent otherEvent) {
		return startTime.compareTo(otherEvent.getStartTime());
	}

}
