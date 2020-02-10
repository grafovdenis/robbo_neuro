# robbo_neuro

Flutter application, created to control external device and visualize some data.

![app](https://spbpu.com/wp-content/uploads/2019/10/platforma_photo.jpg).

App gets characteristics from BLE device every 100ms, shows it, and sends modified data to external device using Bluetooth SPP to control it.  

All data manipulation is located in `lib/widgets/service_data.dart`.