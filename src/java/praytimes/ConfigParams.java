package praytimes;

import java.net.URLDecoder;
import java.net.URLEncoder;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.StringUtils;

public class ConfigParams extends TreeMap<String, Object> {

	private static final long serialVersionUID = -1L;

	private static final Logger log = Logger.getLogger(ConfigParams.class.getName());

	private static final Map<String, Class<?>> VALIDPARAMS = new HashMap<String, Class<?>>();
	static {
		VALIDPARAMS.put(Config.LOCATION, String.class);
		VALIDPARAMS.put(Config.LATITUDE, Double.class);
		VALIDPARAMS.put(Config.LONGITUDE, Double.class);
		VALIDPARAMS.put(Config.TZ, String.class);
		VALIDPARAMS.put(Config.TZ_DST_OFFSET, Integer.class);
		VALIDPARAMS.put(Config.AUTO_FIQH, Integer.class);
		VALIDPARAMS.put(Config.ASR_METHOD, Integer.class);
		VALIDPARAMS.put(Config.FAJR_METHOD, Integer.class);
		VALIDPARAMS.put(Config.FAJR_VALUE, Double.class);
		VALIDPARAMS.put(Config.MAGHRIB_METHOD, Integer.class);
		VALIDPARAMS.put(Config.MAGHRIB_VALUE, Double.class);
		VALIDPARAMS.put(Config.ISHA_METHOD, Integer.class);
		VALIDPARAMS.put(Config.ISHA_VALUE, Double.class);
		VALIDPARAMS.put(Config.HIGHALT_METHOD, Integer.class);
		VALIDPARAMS.put(Config.MIDNIGHT_METHOD, Integer.class);
		VALIDPARAMS.put(Config.FAJR_OFFSET, Integer.class);
		VALIDPARAMS.put(Config.DHUHR_OFFSET, Integer.class);
		VALIDPARAMS.put(Config.ASR_OFFSET, Integer.class);
		VALIDPARAMS.put(Config.MAGHRIB_OFFSET, Integer.class);
		VALIDPARAMS.put(Config.ISHA_OFFSET, Integer.class);
		VALIDPARAMS.put(Config.SUHOOR_OFFSET, Integer.class);
		VALIDPARAMS.put(Config.SUNSET_ALERT, Integer.class);
		VALIDPARAMS.put(Config.SUNRISE_ALERT, Integer.class);
		VALIDPARAMS.put(Config.QIYAM_ALERT, Integer.class);
		VALIDPARAMS.put(Config.TAHAJJUD_ALERT, Integer.class);
		VALIDPARAMS.put(Config.SUHOOR_ALERT, Integer.class);
		VALIDPARAMS.put(Config.NOT_CONFIGURED, Integer.class);
		VALIDPARAMS.put(Config.JUMAAH_SETTING, Integer.class);
		VALIDPARAMS.put(Config.EVENT_END, Integer.class);
	}

	private HttpServletRequest request;
	private Set<String> overrideParams = new HashSet<String>();

	public ConfigParams() {
		super();
	}

	public ConfigParams(HttpServletRequest request, ConfigParams defaults) {
		this.request = request;
		for (Map.Entry<String, Object> entry : defaults.entrySet()) {
			set(entry.getKey(), entry.getValue());
		}
	}

	public ConfigParams(ConfigParams params) {
		super(params);
	}

	public Set<String> getOverrideParams() {
		return overrideParams;
	}
	
	public ConfigParams load() {
		// load from cookie
		{
			Cookie[] cookies = request.getCookies();
			if (!ArrayUtils.isEmpty(cookies)) {
				for (Cookie cookie : cookies) {
					if (cookie.getName().equals("CONFIG")) {
						load(cookie.getValue());
						remove(Config.NOT_CONFIGURED);
						log.fine("loading params from cookie: " + toString());
					}
				}
			}
		}
		// load from path (new)
		{
			String path = request.getPathInfo();
			if (path != null) {
				if (request.getServletPath().equals("/loc") || request.getServletPath().equals("/ics")) {
					String[] pathToks = path.split("/", 3);
					setString(Config.LOCATION, pathToks[1]);
					log.fine("location=" + getString(Config.LOCATION) + ", path=" + pathToks[1]);
					if (pathToks.length > 2)
						load(pathToks[2], true);
				} else {
					load(path, true);
				}
				log.fine("loading params from path: " + toString());
				remove(Config.NOT_CONFIGURED);
			}
		}
		// load from query string (classic)
		{
			Map<String, String[]> pairs = request.getParameterMap();
			if (!pairs.isEmpty()) {
				load(toString2(request.getParameterMap()), true);
				remove(Config.NOT_CONFIGURED);
				log.fine("loading params from query: " + toString());
			}
			String l = null;
			if (request.getServletPath().contains(".ics"))
				l = StringUtils.replace(request.getServletPath().substring(1), ".ics", "");
			else if (request.getServletPath().contains(".html"))
				l = StringUtils.replace(request.getServletPath().substring(1), ".html", "");
			if (l != null) {
				l = StringUtils.defaultIfBlank(l, "Unknown");
				setString(Config.LOCATION, l);
			}
		}
		return this;
	}

	public ConfigParams store(HttpServletResponse response) {
		remove(Config.NOT_CONFIGURED);
		remove(Config.AUTO_FIQH);
		if (containsKey(Config.TZ)) {
			log.fine("remvoing tz offset " + getInteger(Config.TZ_DST_OFFSET) + " in preference to " + getString(Config.TZ));
			remove(Config.TZ_DST_OFFSET);
		}
		log.fine("cookie: " + toString());
		Cookie cookie = new Cookie("CONFIG", toString());
		cookie.setPath("/");
		cookie.setMaxAge(6 * 30 * 24 * 60 * 60);
		response.addCookie(cookie);
		return this;
	}

	public String getString(String name) {
		String value = StringUtils.trimToEmpty(super.get(name).toString());
		if (StringUtils.equalsIgnoreCase(value, "") || StringUtils.equalsIgnoreCase(value, "null"))
			return "";
		return value;
	}

	public ConfigParams setString(String name, String value) {
		value = StringUtils.trimToEmpty(value);
		if (StringUtils.equalsIgnoreCase(value, "") || StringUtils.equalsIgnoreCase(value, "null"))
			value = "";
		put(name, value);
		return this;
	}

	public Integer getInteger(String name) {
		try {
			return Integer.parseInt(super.get(name).toString());
		} catch (Exception e) {
			return Integer.MIN_VALUE;
		}
	}

	public ConfigParams setInteger(String name, Integer value) {
		put(name, value);
		return this;
	}

	public Double getDouble(String name) {
		try {
			return Double.parseDouble(super.get(name).toString());
		} catch (Exception e) {
			return Double.MIN_VALUE;
		}
	}

	public ConfigParams setDouble(String name, Double value) {
		put(name, value);
		return this;
	}

	@Override
	public Object get(Object name) {
		if (VALIDPARAMS.get(name) == String.class) {
			try {
				return URLDecoder.decode(getString((String) name), "UTF-8");
			} catch (Exception e) {
				return getString((String) name);
			}
		} else if (VALIDPARAMS.get(name) == Integer.class) {
			return getInteger((String) name);
		} else if (VALIDPARAMS.get(name) == Double.class) {
			return getDouble((String) name);
		} else {
			log.warning("cannot get unsupported type " + VALIDPARAMS.get(name));
		}
		return null;
	}

	public ConfigParams set(String name, Object value) {
		try {
			if (VALIDPARAMS.get(name) == String.class) {
				try {
					setString(name, URLDecoder.decode((String) value, "UTF-8"));
				} catch (Exception e) {
					setString(name, (String) value);
				}
			} else if (VALIDPARAMS.get(name) == Integer.class) {
				setInteger(name, (Integer) value);
			} else if (VALIDPARAMS.get(name) == Double.class) {
				setDouble(name, (Double) value);
			} else {
				log.warning("cannot set unsupported type " + VALIDPARAMS.get(name));
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "setting " + name + "=" + value + ", expecting type " + VALIDPARAMS.get(name)
					+ " however found type " + value.getClass().getName(), e);
		}
		return this;
	}

	public ConfigParams set(String name, String value) {
		try {
			if (VALIDPARAMS.get(name) == String.class) {
				try {
					setString(name, URLDecoder.decode(value, "UTF-8"));
				} catch (Exception e) {
					setString(name, value);
				}
			} else if (VALIDPARAMS.get(name) == Integer.class) {
				setInteger(name, Integer.parseInt(value));
			} else if (VALIDPARAMS.get(name) == Double.class) {
                                if (name.equals("y") && value.contains("ics")) {
                                    value = value.replaceFirst("ics.*", "");
                                }
				setDouble(name, Double.parseDouble(value));
			} else {
				log.warning("cannot set unsupported type " + VALIDPARAMS.get(name));
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "setting " + name + "=" + value + ", expecting type " + VALIDPARAMS.get(name)
					+ " however found type " + value.getClass().getName(), e);
		}
		return this;
	}

	@Override
	public String toString() {
		return toString(false);
	}

	public String toStringNoDefaults() {
		return toString(true);
	}

	public String toString(boolean excludeDefaults) {
		StringBuilder configString = new StringBuilder();
		int n = 0;
		for (Map.Entry<String, Object> pair : entrySet()) {
			if (!VALIDPARAMS.containsKey(pair.getKey()))
				continue;
			if (excludeDefaults && !pair.getKey().equals(Config.TZ) && !pair.getKey().equals(Config.TZ_DST_OFFSET)) {
				Object defaultValue = Config.DEFAULTS.get(pair.getKey());
				if (defaultValue != null && defaultValue.equals(pair.getValue()))
					continue;
			}
			if (n++ > 0)
				configString.append(':');
			try {
				String value = null;
				if (pair.getValue() instanceof String[])
					value = ((String[]) pair.getValue())[0];
				else
					value = pair.getValue().toString();
				configString.append(pair.getKey()).append('=').append(URLEncoder.encode(value, "UTF-8"));
			} catch (Exception e) {
				log.log(Level.SEVERE, "Unable to create config string from: " + this, e);
			}
		}
		return configString.toString();
	}

	private ConfigParams load(String configString) {
		return load(configString, false);
	}

	private ConfigParams load(String configString, boolean override) {
		String pairDelim = "=";
		String paramDelim = ":";
		if (configString.contains("#")) {
			pairDelim = ":";
			paramDelim = "#";
		}
		try {
			String[] pairs = configString.split(paramDelim);
			for (String pair : pairs) {
				String[] tokens = pair.split(pairDelim);
				if (override)
					overrideParams.add(tokens[0]);
				if (tokens.length > 1)
					set(tokens[0], tokens[1]);
				else {
					if (tokens[0].equals(Config.LOCATION))
						set(tokens[0], "Unknown");
				}
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "Unable to load values from config string: " + configString, e);
		}
		return this;
	}

	private static String toString2(Map<String, String[]> map) {
		StringBuilder configString = new StringBuilder();
		int n = 0;
		for (Map.Entry<String, String[]> pair : map.entrySet()) {
			if (!VALIDPARAMS.containsKey(pair.getKey()))
				continue;
			if (n++ > 0)
				configString.append(':');
			try {
				configString.append(pair.getKey()).append('=').append(URLEncoder.encode(pair.getValue()[0], "UTF-8"));
			} catch (Exception e) {
				log.log(Level.SEVERE, "Unable to create config string from: " + map, e);
			}
		}
		return configString.toString();
	}

}