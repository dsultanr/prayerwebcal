package praytimes;

import java.net.URLEncoder;
import java.time.OffsetDateTime;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang3.StringUtils;

public class Config {

	public enum FactoryCalcMethodParamNames {
		FajrAngle, MaghribMethod, MaghribValue, IshaMethod, IshaValue
	};

	public enum AutoFiqhOption {
		Jafari, Karachi, ISNA, MWL, Makkah, Egypt, Tehran, Custom
	};

	public enum AsrMethodOption {
		EqualToShadowLength, TwiceTheShadowLength
	};

	public enum NightMethodOption {
		AngleBased, MinutesBased
	};

	public enum MidnightMethodOption {
		SunsetToSunrise, SunsetToFajr
	}

	public enum HighAltitudeMethodOption {
		None, Midnight, OneSeventh, AngleBased
	}

	public enum EventEndOption {
		TwentyMinutes, ThirtyMinutes, FourtyMinutes, PreferEnd
	}

	private static final Logger log = Logger.getLogger(Config.class.getName());

	public static final String NOT_CONFIGURED = "notconfigured"; // string
	public static final String LOCATION = "l"; // string
	public static final String LATITUDE = "x"; // double
	public static final String LONGITUDE = "y"; // double
	public static final String TZ_DST_OFFSET = "z"; // int
	public static final String TZ = "tz"; // string
	public static final String AUTO_FIQH = "s"; // int
	public static final String ASR_METHOD = "j"; // int
	public static final String FAJR_METHOD = "f"; // int
	public static final String FAJR_VALUE = "fv"; // double
	public static final String MAGHRIB_METHOD = "m"; // int
	public static final String MAGHRIB_VALUE = "mv"; // double
	public static final String ISHA_METHOD = "i"; // int
	public static final String ISHA_VALUE = "iv"; // double
	public static final String HIGHALT_METHOD = "xm"; // int
	public static final String MIDNIGHT_METHOD = "mn"; // int
	public static final String FAJR_OFFSET = "fo"; // int
	public static final String DHUHR_OFFSET = "do"; // int
	public static final String ASR_OFFSET = "ao"; // int
	public static final String MAGHRIB_OFFSET = "mo"; // int
	public static final String ISHA_OFFSET = "io"; // int
	public static final String SUHOOR_OFFSET = "so"; // int
	public static final String SUNSET_ALERT = "cs"; // int
	public static final String SUNRISE_ALERT = "csr"; // int
	public static final String QIYAM_ALERT = "cq"; // int
	public static final String TAHAJJUD_ALERT = "ct"; // int
	public static final String SUHOOR_ALERT = "csu"; // int
	public static final String JUMAAH_SETTING = "js"; // int
	public static final String EVENT_END = "ee"; // int
	public static final ConfigParams DEFAULTS = new ConfigParams();
	static {
		DEFAULTS.put(LOCATION, "New York, NY, USA");
		DEFAULTS.put(LATITUDE, 40.7128);
		DEFAULTS.put(LONGITUDE, -74.0060);
		DEFAULTS.put(TZ, "America/New_York");
		DEFAULTS.put(ASR_METHOD, AsrMethodOption.EqualToShadowLength.ordinal());
		DEFAULTS.put(FAJR_METHOD, NightMethodOption.AngleBased.ordinal());
		DEFAULTS.put(FAJR_VALUE, 15.);
		DEFAULTS.put(MAGHRIB_METHOD, NightMethodOption.MinutesBased.ordinal());
		DEFAULTS.put(MAGHRIB_VALUE, 0.);
		DEFAULTS.put(ISHA_METHOD, NightMethodOption.AngleBased.ordinal());
		DEFAULTS.put(ISHA_VALUE, 15.);
		DEFAULTS.put(HIGHALT_METHOD, HighAltitudeMethodOption.AngleBased.ordinal());
		DEFAULTS.put(MIDNIGHT_METHOD, MidnightMethodOption.SunsetToFajr.ordinal());
		DEFAULTS.put(FAJR_OFFSET, 0);
		DEFAULTS.put(DHUHR_OFFSET, 0);
		DEFAULTS.put(ASR_OFFSET, 0);
		DEFAULTS.put(MAGHRIB_OFFSET, 0);
		DEFAULTS.put(ISHA_OFFSET, 0);
		DEFAULTS.put(SUHOOR_OFFSET, -45);
		DEFAULTS.put(SUNSET_ALERT, 0);
		DEFAULTS.put(SUNRISE_ALERT, 1);
		DEFAULTS.put(QIYAM_ALERT, 1);
		DEFAULTS.put(TAHAJJUD_ALERT, 1);
		DEFAULTS.put(SUHOOR_ALERT, 1);
		DEFAULTS.put(JUMAAH_SETTING, 0);
		DEFAULTS.put(EVENT_END, 1);
		DEFAULTS.put(NOT_CONFIGURED, 1);
	}

	private HttpServletRequest request;
	private PrayTimeFactory factory = new PrayTimeFactory();
	private ConfigParams params;
	private int tzOffset;

	public Config(HttpServletRequest request) throws Exception {
		this.request = request;
		params = new ConfigParams(request, DEFAULTS).load();
		log.fine("override params: " + params.getOverrideParams());
		if (params.getOverrideParams().contains(TZ)) {
			TimeZone tz = TimeZone.getTimeZone(params.getString(TZ));
			tzOffset = (int) TimeUnit.MILLISECONDS.toMinutes(tz.getOffset(System.currentTimeMillis()));
			params.remove(TZ_DST_OFFSET);
			log.fine("using tz=" + params.getString(TZ) + " " + tzOffset + " min.");
		} else if (params.containsKey(TZ_DST_OFFSET)) {
			tzOffset = params.getInteger(TZ_DST_OFFSET);
			params.remove(TZ);
			log.fine("using tz offset=" + params.getInteger(TZ_DST_OFFSET) + " min.");
		} else {
			TimeZone tz = TimeZone.getTimeZone(params.getString(TZ));
			tzOffset = (int) TimeUnit.MILLISECONDS.toMinutes(tz.getOffset(System.currentTimeMillis()));
			params.remove(TZ_DST_OFFSET);
			log.fine("using tz=" + params.getString(TZ) + " " + tzOffset + " min.");
		}
		setAsrMethod(getAsrMethod());
		if (isAutoFiqh()) {
			setAutoFiqh(getAutoFiqh());
			int s = getAutoFiqh();
			setFajrMethod(NightMethodOption.AngleBased.ordinal())
					.setFajrValue(factory.methodParams.get(s)[FactoryCalcMethodParamNames.FajrAngle.ordinal()]);
			setMaghribMethod((int) factory.methodParams.get(s)[FactoryCalcMethodParamNames.MaghribMethod.ordinal()])
					.setMaghribValue(factory.methodParams.get(s)[FactoryCalcMethodParamNames.MaghribValue.ordinal()]);
			setIshaMethod((int) factory.methodParams.get(s)[FactoryCalcMethodParamNames.IshaMethod.ordinal()])
					.setIshaValue(factory.methodParams.get(s)[FactoryCalcMethodParamNames.IshaValue.ordinal()]);
			setHighAltitudeMethod(HighAltitudeMethodOption.AngleBased.ordinal());
			params.remove(AUTO_FIQH);
		} else {
			setFajrMethod(getFajrMethod()).setFajrValue(getFajrValue());
			setMaghribMethod(getMaghribMethod()).setMaghribValue(getMaghribValue());
			setIshaMethod(getIshaMethod()).setIshaValue(getIshaValue());
			setHighAltitudeMethod(getHighAltitudeMethod());
		}
		setSunsetAlert(getSunsetAlert());
		setSunriseAlert(getSunriseAlert());
		setQiyamAlert(getQiyamAlert());
		setTahajjudAlert(getTahajjudAlert());
		setSuhoorAlert(getSuhoorAlert());
		setOffsets(getOffsets());
		setSuhoorOffset(getSuhoorOffset());
		setJumaahSetting(getJumaahSetting());
		setEventEnd(getEventEnd());

		log.fine("cfg: " + params.toString() + ", factory:" + factory.toString());
	}

	public List<String> getPrayerTimes(OffsetDateTime when) {
		Calendar whenDate = GregorianCalendar.from(when.toZonedDateTime());
		return factory.getPrayerTimes(whenDate, getLatitude(), getLongitude(), 0.);
	}

	public void store(HttpServletResponse response) {
		params.store(response);
	}

	public PrayTimeFactory getFactory() {
		return factory;
	}

	public String getLocation() {
		return params.getString(LOCATION).replaceAll("_", " ");
	}

	public Double getLatitude() {
		return params.getDouble(LATITUDE);
	}

	public Double getLongitude() {
		return params.getDouble(LONGITUDE);
	}

	public Integer getTZDSTOffset() {
		return tzOffset;
	}

	public String getTimeZone() {
		return params.getString(TZ);
	}

	public Boolean isTimeZone() {
		return params.containsKey(TZ);
	}

	public Boolean isAutoFiqh() {
		return params.containsKey(AUTO_FIQH);
	}

	public Integer getAutoFiqh() {
		return params.getInteger(AUTO_FIQH);
	}

	public Config setAutoFiqh(Integer value) {
		params.put(AUTO_FIQH, value);
		factory.setCalcMethod(value);
		return this;
	}

	public Integer getFajrMethod() {
		return params.getInteger(FAJR_METHOD);
	}

	private Config setFajrMethod(Integer value) {
		params.put(FAJR_METHOD, value);
		return this;
	}

	public Double getFajrValue() {
		return params.getDouble(FAJR_VALUE);
	}

	private Config setFajrValue(Double value) {
		params.put(FAJR_VALUE, value);
		if (getFajrMethod() == NightMethodOption.AngleBased.ordinal())
			factory.setFajrAngle(value);
		return this;
	}

	public Integer getAsrMethod() {
		return params.getInteger(ASR_METHOD);
	}

	private Config setAsrMethod(Integer value) {
		params.put(ASR_METHOD, value);
		factory.setAsrJuristic(value);
		return this;
	}

	public Integer getMaghribMethod() {
		return params.getInteger(MAGHRIB_METHOD);
	}

	private Config setMaghribMethod(Integer value) {
		params.put(MAGHRIB_METHOD, value);
		return this;
	}

	public Double getMaghribValue() {
		return params.getDouble(MAGHRIB_VALUE);
	}

	private Config setMaghribValue(Double value) {
		params.put(MAGHRIB_VALUE, value);
		if (getMaghribMethod() == NightMethodOption.AngleBased.ordinal())
			factory.setMaghribAngle(value);
		else if (getMaghribMethod() == NightMethodOption.MinutesBased.ordinal())
			factory.setMaghribMinutes(value);
		return this;
	}

	public Integer getIshaMethod() {
		return params.getInteger(ISHA_METHOD);
	}

	private Config setIshaMethod(Integer value) {
		params.put(ISHA_METHOD, value);
		return this;
	}

	public Double getIshaValue() {
		return params.getDouble(ISHA_VALUE);
	}

	private Config setIshaValue(Double value) {
		params.put(ISHA_VALUE, value);
		if (getIshaMethod() == NightMethodOption.AngleBased.ordinal())
			factory.setIshaAngle(value);
		else if (getIshaMethod() == NightMethodOption.MinutesBased.ordinal())
			factory.setIshaMinutes(value);
		return this;
	}

	public Integer getMidnightMethod() {
		return params.getInteger(MIDNIGHT_METHOD);
	}

	public Integer getEventEnd() {
		return params.getInteger(EVENT_END);
	}

	public Integer getHighAltitudeMethod() {
		return params.getInteger(HIGHALT_METHOD);
	}

	private Config setHighAltitudeMethod(Integer value) {
		params.put(HIGHALT_METHOD, value);
		factory.setAdjustHighLats(value);
		return this;
	}

	public int[] getOffsets() {
		return new int[] { getFajrOffset(), 0, getDhuhrOffset(), getAsrOffset(), 0, getMaghribOffset(), getIshaOffset() };
	}

	public int[] setOffsets(int[] offsets) {
		setFajrOffset(offsets[PrayEvent.Type.Fajr.ordinal()]);
		setDhuhrOffset(offsets[PrayEvent.Type.Dhuhr.ordinal()]);
		setAsrOffset(offsets[PrayEvent.Type.Asr.ordinal()]);
		setMaghribOffset(offsets[PrayEvent.Type.Maghrib.ordinal()]);
		setIshaOffset(offsets[PrayEvent.Type.Isha.ordinal()]);
		factory.tune(offsets);
		return offsets;
	}

	public Integer getFajrOffset() {
		return params.getInteger(FAJR_OFFSET);
	}

	private Config setFajrOffset(Integer value) {
		params.put(FAJR_OFFSET, value);
		return this;
	}

	public Integer getDhuhrOffset() {
		return params.getInteger(DHUHR_OFFSET);
	}

	private Config setDhuhrOffset(Integer value) {
		params.put(DHUHR_OFFSET, value);
		return this;
	}

	public Integer getAsrOffset() {
		return params.getInteger(ASR_OFFSET);
	}

	private Config setAsrOffset(Integer value) {
		params.put(ASR_OFFSET, value);
		return this;
	}

	public Integer getMaghribOffset() {
		return params.getInteger(MAGHRIB_OFFSET);
	}

	private Config setMaghribOffset(Integer value) {
		params.put(MAGHRIB_OFFSET, value);
		return this;
	}

	public Integer getIshaOffset() {
		return params.getInteger(ISHA_OFFSET);
	}

	private Config setIshaOffset(Integer value) {
		params.put(ISHA_OFFSET, value);
		return this;
	}

	public Integer getSuhoorOffset() {
		return params.getInteger(SUHOOR_OFFSET);
	}

	private Config setSuhoorOffset(Integer value) {
		params.put(SUHOOR_OFFSET, value);
		return this;
	}

	public Integer getSunsetAlert() {
		return params.getInteger(SUNSET_ALERT);
	}

	public Integer getSunriseAlert() {
		return params.getInteger(SUNRISE_ALERT);
	}

	private Config setSunsetAlert(Integer value) {
		params.put(SUNSET_ALERT, value);
		return this;
	}

	private Config setSunriseAlert(Integer value) {
		params.put(SUNRISE_ALERT, value);
		return this;
	}

	public Integer getQiyamAlert() {
		return params.getInteger(QIYAM_ALERT);
	}

	private Config setQiyamAlert(Integer value) {
		params.put(QIYAM_ALERT, value);
		return this;
	}

	public Integer getTahajjudAlert() {
		return params.getInteger(TAHAJJUD_ALERT);
	}

	private Config setTahajjudAlert(Integer value) {
		params.put(TAHAJJUD_ALERT, value);
		return this;
	}

	public Integer getSuhoorAlert() {
		return params.getInteger(SUHOOR_ALERT);
	}

	private Config setSuhoorAlert(Integer value) {
		params.put(SUHOOR_ALERT, value);
		return this;
	}

	public Integer getJumaahSetting() {
		return params.getInteger(JUMAAH_SETTING);
	}

	private Config setJumaahSetting(Integer value) {
		params.put(JUMAAH_SETTING, value);
		return this;
	}

	private Config setEventEnd(Integer value) {
		params.put(EVENT_END, value);
		return this;
	}

	public String getSecureHost() {
		if (getHostName().contains("localhost"))
			return "http://" + getHostName();
		return "https://" + getHostName();
	}

	public String getHostName() {
		String port = (request.getServerPort() == 80 || request.getServerPort() == 443) ? "" : ":" + request.getServerPort();
		return request.getServerName() + port;
	}

	public String getICSPath() throws Exception {
		return getPath(true);
	}

	public String getPath() throws Exception {
		return getPath(false);
	}

	public String getPath(boolean ics) throws Exception {
		ConfigParams urlParams = new ConfigParams(params);
		String l = clean(getLocation());
		if (l == null)
			l = "";
		l = URLEncoder.encode(l, "UTF-8");
		l = StringUtils.replace(l, "+", "%20");
		urlParams.remove(LOCATION);
		if (ics)
			return new StringBuilder("ics/").append(l).append("/").append(urlParams.toStringNoDefaults()).toString();
		else
			return new StringBuilder("/loc/").append(l).append("/").append(urlParams.toStringNoDefaults()).toString();
	}

	@Override
	public String toString() {
		return params.toString();
	}

	public String toStringNoDefaults() {
		return params.toStringNoDefaults();
	}

	public static String clean(String value) {
		value = StringUtils.stripAccents(value);
		return StringUtils.trimToEmpty(value).replaceAll("[^a-zA-Z0-9\\_]", "_").replaceAll("_+", "_");
	}

}
