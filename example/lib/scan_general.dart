import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_scankit/flutter_scankit.dart';
import 'package:flutter_scankit_example/home2.dart';
import 'package:flutter_scankit_example/http_client.dart';
import 'package:flutter_scankit_example/user_role.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'package:vibration/vibration.dart';

// 通用

const boxSize = 400.0;

class ScanGeneralScreen extends StatefulWidget {
  const ScanGeneralScreen({Key? key}) : super(key: key);

  @override
  State<ScanGeneralScreen> createState() => _CustomViewState();
}

class _CustomViewState extends State<ScanGeneralScreen>
    with RouteAware, WidgetsBindingObserver {
  ScanKitController _controller = ScanKitController();

  StreamSubscription<Object?>? _subscription;
  bool _isProcessing = false;
  bool _isResultDisplayed = false; // 控制处理结果的显示与隐藏
  String scanResultText = "扫码中...";
  String scanInfoText = "请扫码！";
  Color scanResultColor = Colors.grey;

  ScanResult? _barcode;

  @override
  void initState() {
    _subscription = _controller.onResult.listen(_handleBarcode);

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = _controller.onResult.listen(_handleBarcode);

        break;
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
    }
  }

  void _handleBarcode(ScanResult barcode) {
    debugPrint(
        "scanning result:value=${barcode.originalValue} scanType=${barcode.scanType}");
    // final provider =
    //     Provider.of<BottomNavigationBarProvider>(context, listen: false);
    if (mounted) {
      debugPrint("cur run wiget ${widget.runtimeType.toString()} ");

      if (!_isProcessing) {
        setState(() {
          _isProcessing = true;
          _barcode = barcode;
          if (_barcode != null) {
            _processScanResult(_barcode!.originalValue); // 处理扫描结果
          } else {
            debugPrint("_barcode is null");
          }
        });
      }
    }
  }

  Future<void> _processScanResult(String? result) async {
    // 检查扫描结果的格式
    if (await isMatch(result)) {
      doProcess(result!);
    } else {
      scanResultText = "非有效单号";
      scanResultColor = Colors.red;
    }
    // 显示结果，1秒后隐藏结果层并重置状态
    setState(() {
      _isResultDisplayed = true;
    });
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isResultDisplayed = false;
      _isProcessing = false;
      scanResultText = "扫码中...";
      scanResultColor = Colors.grey;
      scanInfoText = "请扫码！";
    });
  }

  Future<bool> isMatch(result) async {
    if (result != null && (RegExp(r'^\d+\$xiaowangniujin$').hasMatch(result))) {
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    var left = screenWidth / 2 - boxSize / 2;
    var top = screenHeight / 2 - boxSize / 2;
    var rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ScanKitWidget(
                controller: _controller,
                continuouslyScan: true,
                boundingBox: rect),
            Align(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {
                        _controller.switchLight();
                      },
                      icon: Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 28,
                      )),
                  IconButton(
                      onPressed: () {
                        _controller.pickPhoto();
                      },
                      icon: Icon(
                        Icons.photo,
                        color: Colors.white,
                        size: 28,
                      ))
                ],
              ),
            ),
            _buildResultLayer(), // 处理结果
            Align(
              alignment: Alignment.center,
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: Colors.blue, width: 1),
                      right: BorderSide(color: Colors.blue, width: 1),
                      top: BorderSide(color: Colors.blue, width: 1),
                      bottom: BorderSide(color: Colors.blue, width: 1)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                alignment: Alignment.bottomCenter,
                height: 100,
                color: Colors.black.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: Center(child: _buildBarcode(_barcode))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcode(ScanResult? value) {
    if (!_isResultDisplayed) {
      scanInfoText = "请扫码！";
    } else {
      if (value != null) {
        scanInfoText = value.originalValue;
      }
    }

    return Text(
      scanInfoText,
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    );
  }

  Widget _buildResultLayer() {
    if (!_isResultDisplayed) {
      return const SizedBox.shrink(); // 如果不需要显示结果，返回一个空的小部件
    }

    return Container(
      color: Colors.black.withOpacity(0.5), // 半透明背景
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            scanResultText,
            style: TextStyle(
                color: scanResultColor,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void doProcess(String result) async {
    Role role = Provider.of<RoleManager>(context, listen: false).role;
    String operation = role.roleName;
    String operationCode = role.roleCode;

    RegExp pattern = RegExp(r'\d+');
    RegExpMatch? match = pattern.firstMatch(result);

    String? orderIdStr = match?.group(0);
    if (orderIdStr == null) {
      //异常了
      return;
    }

    int orderId = int.parse(orderIdStr);

    bool hasProcessed = await isProcessed(operationCode, orderId);

    if (hasProcessed) {
      scanResultText = "已$operation扫码\n$orderId";
      scanResultColor = Colors.yellow;
    } else {
      try {
        var response = await httpClient(
          uri: Uri.parse('$httpHost/app/order/scan'),
          body: {
            'orderIdQr': result,
            'operation': operationCode,
          },
          method: 'POST',
        );
        if (response.isSuccess) {
          Vibration.vibrate();
          setState(() {
            scanResultText = "$operation扫码成功\n$orderId";
            scanResultColor = Colors.green;
          });
          setProcessed(operationCode, orderId);
        } else {
          String msg = response.message;
          setState(() {
            scanResultText = "$msg\n$orderId";
            scanResultColor = Colors.red;
          });
        }
      } catch (e) {
        setState(() {
          scanResultText = "扫码异常\n$orderId";
          scanResultColor = Colors.red;
        });
      }
    }
  }

  Future<bool> isProcessed(String operationCode, int orderId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = _makeScanKey(operationCode, orderId);
    int? lastTimestamp = prefs.getInt(key);
    int currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    if (lastTimestamp == null ||
        (currentTimeMillis - lastTimestamp) >= 5 * 60 * 1000) {
      return false;
    }
    return true;
  }

  void setProcessed(String operationCode, int orderId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = _makeScanKey(operationCode, orderId);
    int currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    prefs.setInt(key, currentTimeMillis);
  }

  String _makeScanKey(String operationCode, int orderId) {
    String key = 'prefix$operationCode$orderId';
    return key;
  }
}
