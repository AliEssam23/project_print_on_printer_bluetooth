import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:path_provider/path_provider.dart';
import 'package:project_print_on_printer_bluetooth/printer_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: PrintersView());
  }
}
// }

class PrintersView extends StatefulWidget {
  const PrintersView({Key? key}) : super(key: key);

  @override
  State<PrintersView> createState() => _PrintersViewState();
}

class _PrintersViewState extends State<PrintersView> {
  late File imgFile;

  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    bluetooth_scan();

    _initImg();
  }

  bluetooth_scan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        bool isDeviceAlreadyAdded =
            devicesList.any((device) => device.id == r.device.id);

        if (!isDeviceAlreadyAdded) {
          setState(() {
            devicesList.add(r.device);
          });
          print('${r.device.name}: "${r.device.id}" found!');
        } else {
          print('${r.device.name}: "${r.device.id}" is already in the list!');
        }
      }
    });
  }

  _initImg() async {
    try {
      ByteData byteData = await rootBundle.load("images/flutter.png");
      Uint8List buffer = byteData.buffer.asUint8List();
      String path = (await getTemporaryDirectory()).path;
      imgFile = File("$path/img.png");
      imgFile.writeAsBytes(buffer);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Bluetooth Printer"),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            bluetooth_scan();
          },
          child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 248, 248),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(devicesList[index].name.toString()),
                        titleTextStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        subtitle: Text(devicesList[index].remoteId.toString()),
                        onTap: () {
                          _connect(devicesList[index].remoteId.toString());
                          _methodPrint(imgFile.path);
                        },
                      ),
                    ),
                  ],
                );
              }),
        ));
  }

  void _connect(String macAddress) async {
    try {{
      await PrinterManager.connect(macAddress);}
      print("Connected to $macAddress");
    } catch (e) {
      print("Error connecting to $macAddress: $e");
    }
  }

  void _methodPrint(String path) async {
    try {
      await PrinterManager.printImg(imgFile.path);
      print("Printing image...");
    } catch (e) {
      print("Error printing image: $e");
    }
  }
}
