package praytimes;

import java.util.Calendar;
import java.util.Iterator;

public class CalendarIterator implements Iterator<Calendar>, Iterable<Calendar> {

	public static final int DAYS_MAX = 3 * 30;
	private Calendar cal;
	private int dayCount = 0;

	public CalendarIterator() {
		cal = Calendar.getInstance();
		cal.set(Calendar.HOUR, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		cal.add(Calendar.DATE, -15);
	}

	public Calendar getCalendar() {
		return cal;
	}

	@Override
	public boolean hasNext() {
		return dayCount <= DAYS_MAX;
	}

	@Override
	public Calendar next() {
		cal.add(Calendar.DAY_OF_MONTH, 1);
		dayCount++;
		return cal;
	}

	@Override
	public void remove() {
	}

	@Override
	public Iterator<Calendar> iterator() {
		return this;
	}

}
