import '../services/api_service.dart';
import '../models/event_booking.dart';
import '../models/food.dart';

class EventRepository {
  Future<EventBooking> createBooking(Map<String, dynamic> data) async {
    final response = await ApiService.post('/events', data);
    return EventBooking.fromJson(response['data']);
  }

  Future<List<EventBooking>> getUserBookings() async {
    final response = await ApiService.get('/events/my-bookings');
    return (response['data'] as List)
        .map((e) => EventBooking.fromJson(e))
        .toList();
  }

  Future<List<EventBooking>> getHotelBookings() async {
    final response = await ApiService.get('/events/hotel-bookings');
    return (response['data'] as List)
        .map((e) => EventBooking.fromJson(e))
        .toList();
  }

  Future<EventBooking> respondToBooking(
      String bookingId, Map<String, dynamic> data) async {
    final response = await ApiService.put('/events/$bookingId/respond', data);
    return EventBooking.fromJson(response['data']);
  }

  Future<List<Food>> getEventRecommendations(String eventType,
      {String? hotelId}) async {
    String url = '/events/recommendations?eventType=$eventType';
    if (hotelId != null) url += '&hotelId=$hotelId';
    final response = await ApiService.get(url);
    return (response['data'] as List).map((e) => Food.fromJson(e)).toList();
  }

  Future<List<dynamic>> getNearbyVenues() async {
    final response = await ApiService.get('/events/venues');
    return response['data'] as List;
  }
}
