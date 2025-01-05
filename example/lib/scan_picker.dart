import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_scankit_example/http_client.dart';
import 'package:flutter_scankit_example/scan.dart';
import 'package:flutter_scankit_example/scan_general.dart';
import 'package:flutter_scankit_example/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'wave_data.dart';
import 'package:vibration/vibration.dart';

import 'wave_detail_picker.dart';

// 拣货用的
class ScanPickerScreen extends StatefulWidget {
  final Wave? wave; // 接收从上一个界面传递过来的Wave对象
  final int type;

  ScanPickerScreen({super.key, this.wave, required this.type});

  @override
  _ScanPickerState createState() => _ScanPickerState();
}

class _ScanPickerState extends State<ScanPickerScreen> {
  late Wave _wave;

  // 从服务器获取波次数据的函数
  Future<Wave> fetchWavesById(int waveId) async {
    final response = await httpClient(
      uri: Uri.parse('$httpHost/app/order/wave/get/$waveId'),
      method: "GET",
    );

    if (response.isSuccess) {
      return Wave.fromJson(response.data);
    } else {
      throw Exception(response.message);
    }
  }

  void fetchData() {
    // 服务器返回的JSON响应会被转换成一个包含Wave对象的列表

    fetchWavesById(widget.wave!.waveId).then((data) {
      setState(() {
        _wave = data;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _wave = widget.wave!;
  }

  @override
  Widget build(BuildContext context) {
    String appBarStr;
    if (widget.type == 1) {
      appBarStr = "配货单加入波次";
    } else {
      appBarStr = "配货单撤出波次";
    }

    dynamic data = {
      'wave': widget.wave,
      'type': widget.type,
      'role': Role(
        roleCode: jianhuoRoleCode,
        roleName: '拣货',
        roleType: 1,
        menuIcon: 'photo',
      )
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarStr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ListTile(
            title: Text('波次编号: ${_wave.waveId}'),
            subtitle: Text(
                '共计${_wave.addressCount}个地址, ${_wave.orderCount}个订单\n创建时间: ${_wave.createTime}'),
            onTap: () {
              // 点击时导航到波次详情页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WaveDetailsPickerScreen(
                    aWave: _wave,
                    result: '',
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: ScanGeneralScreen(
              onCompletion: (String result) {
                fetchData();
              },
              data: data,
            ),
          ),
        ],
      ),
    );
  }
}
