class_name AirportData
extends RefCounted
## Coordinates and names: OurAirports facility records (https://ourairports.com/).
## Present-day clock rules: IANA tz database (https://www.iana.org/time-zones).

const AIRPORTS := {
	"LAX": {"iata": "LAX", "name": "Los Angeles International Airport", "city": "Los Angeles", "country": "US", "lat": 33.942501, "lon": -118.407997, "zone": "America/Los_Angeles", "standard_offset": -8, "dst_rule": "US"},
	"NRT": {"iata": "NRT", "name": "Narita International Airport", "city": "Narita", "country": "JP", "lat": 35.768580, "lon": 140.388714, "zone": "Asia/Tokyo", "standard_offset": 9, "dst_rule": "NONE"},
	"CDG": {"iata": "CDG", "name": "Charles de Gaulle International Airport", "city": "Paris", "country": "FR", "lat": 49.008960, "lon": 2.554117, "zone": "Europe/Paris", "standard_offset": 1, "dst_rule": "EU"},
	"SYD": {"iata": "SYD", "name": "Sydney Kingsford Smith International Airport", "city": "Sydney", "country": "AU", "lat": -33.946098, "lon": 151.177002, "zone": "Australia/Sydney", "standard_offset": 10, "dst_rule": "SYD"},
	"JFK": {"iata": "JFK", "name": "John F. Kennedy International Airport", "city": "New York", "country": "US", "lat": 40.639447, "lon": -73.779317, "zone": "America/New_York", "standard_offset": -5, "dst_rule": "US"},
	"DXB": {"iata": "DXB", "name": "Dubai International Airport", "city": "Dubai", "country": "AE", "lat": 25.249790, "lon": 55.370992, "zone": "Asia/Dubai", "standard_offset": 4, "dst_rule": "NONE"},
	"LHR": {"iata": "LHR", "name": "London Heathrow Airport", "city": "London", "country": "GB", "lat": 51.470748, "lon": -0.459909, "zone": "Europe/London", "standard_offset": 0, "dst_rule": "EU"},
	"SGN": {"iata": "SGN", "name": "Tan Son Nhat International Airport", "city": "Ho Chi Minh City", "country": "VN", "lat": 10.818800, "lon": 106.652000, "zone": "Asia/Ho_Chi_Minh", "standard_offset": 7, "dst_rule": "NONE"},
}


static func get_airport(iata: String) -> Dictionary:
	return AIRPORTS.get(iata, {})


static func local_time(iata: String, unix_utc: float) -> Dictionary:
	var airport: Dictionary = get_airport(iata)
	if airport.is_empty():
		return {}
	var standard: int = airport["standard_offset"]
	var year: int = Time.get_datetime_dict_from_unix_time(int(unix_utc)).year
	var dst := false
	match airport["dst_rule"]:
		"US":
			var march_day := _sunday(year, 3, 2)
			var november_day := _sunday(year, 11, 1)
			var start := _utc(year, 3, march_day, 2 - standard)
			var finish := _utc(year, 11, november_day, 2 - standard - 1)
			dst = unix_utc >= start and unix_utc < finish
		"EU":
			var start := _utc(year, 3, _sunday(year, 3, -1), 1)
			var finish := _utc(year, 10, _sunday(year, 10, -1), 1)
			dst = unix_utc >= start and unix_utc < finish
		"SYD":
			var start := _utc(year, 10, _sunday(year, 10, 1), 2 - standard)
			var finish := _utc(year, 4, _sunday(year, 4, 1), 3 - standard - 1)
			dst = unix_utc >= start or unix_utc < finish
	var local := Time.get_datetime_dict_from_unix_time(int(unix_utc) + (standard + int(dst)) * 3600)
	return {"hour": local.hour, "minute": local.minute, "dst": dst}


static func _utc(year: int, month: int, day: int, hour: int) -> int:
	return Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day, "hour": 0}) + hour * 3600


static func _sunday(year: int, month: int, ordinal: int) -> int:
	var first := _utc(year, month, 1, 0)
	var weekday: int = Time.get_datetime_dict_from_unix_time(first).weekday
	if ordinal > 0:
		return 1 + posmod(7 - weekday, 7) + (ordinal - 1) * 7
	var next_month := _utc(year + 1, 1, 1, 0) if month == 12 else _utc(year, month + 1, 1, 0)
	var last_day := int((next_month - first) / 86400)
	var last_weekday: int = Time.get_datetime_dict_from_unix_time(next_month - 86400).weekday
	return last_day - posmod(last_weekday, 7)
