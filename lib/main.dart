import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

import 'core/bloc/database_bloc/database_bloc.dart';
import 'core/model/notification_model.dart';
import 'core/model/task_model.dart';
import 'core/resources/hive_repository.dart';
import 'ui/screen/menu_dashboard_screen.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();
final BehaviorSubject<String> selectNotification = BehaviorSubject<String>();

NotificationAppLaunchDetails notificationAppLaunchDetails;

var locations;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //
  // HIVE INITIALIZATION
  //
  var dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  Hive.registerAdapter(TasksAdapter());
  Hive.registerAdapter(SubtaskAdapter());
  Hive.registerAdapter(TimeOfDayAdapter());
  await Hive.openBox('taskManager');

  //
  // NOTIFICATION INITIALIZATION
  //
  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      });

  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      selectNotification.add(payload);
    }
  });

  // My App
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    HiveRepository repository = HiveRepository();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MultiBlocProvider(
        providers: [
          BlocProvider<DatabaseBloc>(
            create: (context) => DatabaseBloc(repository),
          ),
        ],
        child: MaterialApp(
            title: 'Task Manager',
            theme: ThemeData(
                primaryColor: Color(0xFFfabb18),
                scaffoldBackgroundColor: Colors.white,
                cursorColor: Color(0xFFfabb18),
                fontFamily: 'Roboto'),
            home: MenuDashboard(currentIndexPage: 0)));
  }
}
