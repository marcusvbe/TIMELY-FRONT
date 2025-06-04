import 'data_service_interface.dart';
import 'rfid_data_service.dart';

class DataServiceProvider {
  static DataServiceInterface getService(
      {required bool useMockData, required String apiBaseUrl}) {
    // Ignore os parâmetros e sempre retorne o RfidDataService
    return RfidDataService();
  }
}
