import 'package:flutter/material.dart';
import 'package:flutter_scankit_example/http_client.dart';
import 'package:flutter_scankit_example/scan_picker.dart';
import 'package:flutter_scankit_example/wave_detail_picker.dart';
import 'package:intl/intl.dart'; // 用于格式化日期
import 'constants.dart';
import 'user_data.dart';
import 'wave_data.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class WaveListScreen extends StatefulWidget {
  final User user;
  const WaveListScreen({
    super.key,
    required this.user,
  });

  @override
  _WaveListScreenState createState() => _WaveListScreenState();
}

class _WaveListScreenState extends State<WaveListScreen> {
  DateTime selectedDate = DateTime.now();
  List<Wave> waves = []; // 波次列表数据
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    fetchData(); // 获得初始化数据
  }

  void fetchData() {
    // 服务器返回的JSON响应会被转换成一个包含Wave对象的列表

    setState(() {
      waves = [];
      _isCompleted = false;
    });

    fetchWavesByDate(selectedDate).then((data) {
      setState(() {
        waves = data;
        _isCompleted = true;
        // controller.stop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.add_box, size: 40),
                onPressed: () {
                  // 显示对话框
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('确认'),
                        content: const Text('新增一个波次？'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              // 关闭对话框
                              Navigator.of(context).pop();
                            },
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              // 关闭对话框
                              Navigator.of(context).pop();
                              _addNewWave();
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                onDoubleTap: () => _selectDate(context),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 40),
                    const SizedBox(
                      width: 10,
                      height: 10,
                    ),
                    Text(DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  size: 40,
                ),
                onPressed: () {
                  fetchData(); // 重新获取数据
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('共计${waves.length}个波次',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: Stack(children: [
              ListView.builder(
                itemCount: waves.length,
                itemBuilder: (context, index) {
                  return WaveItem(
                    wave: waves[index],
                    index: index, // 将索引传递给WaveItem
                    key: ValueKey(
                        waves[index].waveId), // 使用waveId作为唯一key，如果waveId是唯一的话
                    addressCount: waves[index].orderCount,
                    totalCount: waves[index].orderCount,
                  );
                },
              ),
              _buildResultLayer(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultLayer() {
    if (_isCompleted) {
      return const SizedBox.shrink(); // 如果不需要显示结果，返回一个空的小部件
    }

    return Center(
        child: LoadingAnimationWidget.horizontalRotatingDots(
      color: Colors.grey,
      size: 100,
    ));
  }

  Future<void> _selectDate(BuildContext context) async {
    // 获取当前时间的前一天
    final DateTime previousDay =
        DateTime.now().subtract(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: previousDay,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fetchData();
      });
    }
  }

  void _addNewWave() async {
    try {
      // 发送HTTP POST请求，将Wave保存到服务器上
      final response = await httpClient(
        uri: Uri.parse('$httpHost/app/order/wave/create'), // 替换为你的API端点
        body: {},
        method: 'POST',
      );

      // 检查服务器响应是否成功
      if (response.isSuccess) {
        // 解析响应数据创建Wave对象
        fetchData();
      } else {
        throw Exception('出现错误 ${response.message}');
      }
    } catch (error) {
      // 错误处理：网络请求失败等
      print('HTTP请求错误: $error');
    }
  }
}

class WaveItem extends StatefulWidget {
  final Wave wave;
  final int index; // 添加index参数
  final int addressCount;
  final int totalCount;

  const WaveItem(
      {required this.wave,
      required this.index,
      super.key,
      required this.addressCount,
      required this.totalCount});

  @override
  State<StatefulWidget> createState() => WaveItemScreenState();
}

class WaveItemScreenState extends State<WaveItem> {
  final TextEditingController _controller = TextEditingController();
  int shipCount = 0;

  @override
  Widget build(BuildContext context) {
    Wave wave = widget.wave;
    int index = widget.index;
    String shipManText = wave.shipMan ?? '';

    print("wave ${wave.waveId} ${wave.status}");
    return InkWell(
        onTap: () {
          // 点击时导航到波次详情页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaveDetailsPickerScreen(
                aWave: wave,
                result: '',
              ),
            ),
          );
        },
        child: ListTile(
          title: Text(
            '波次: ${wave.waveId}',
            style: Theme.of(context).textTheme.titleSmall,
          ),

          subtitle: Text(
              '地址 ${wave.addressCount}, 订单 ${wave.orderCount}\n${wave.createTime}'),
          leading: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.bodyMedium,
          ), // 显示从1开始的序号
          trailing: wave.status != null && wave.status == 1
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$shipCount',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 20,
                      )),
                  const SizedBox(width: 8), // 设置你想要的间距

                  Text(shipManText,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(width: 8), // 设置你想要的间距

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Colors.blueGrey,
                      ),
                      Text(
                        ' 已发货',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                ] // 图标],
                  )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$shipCount',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 40,
                      ),
                      onPressed: () async {
                        addItemDialog(wave.waveId);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 40,
                      ),
                      onPressed: () async {
                        // 使用Navigator.push方法来跳转到ScanScreen，并传递新的Wave对象
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanPickerScreen(
                              wave: wave,
                              type: 3,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove,
                        color: Colors.red,
                        size: 40,
                      ),
                      onPressed: () async {
                        // 实现减少数量逻辑
                        // 使用Navigator.push方法来跳转到ScanScreen，并传递新的Wave对象
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanPickerScreen(
                              wave: wave,
                              type: 4,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ));
  }

  @override
  void initState() {
    super.initState();
    // 初始化 shipCount
    if (widget.wave.shipCount == null) {
      shipCount = 0;
    } else {
      shipCount = widget.wave.shipCount!;
    }
  }

  Future<void> addItemDialog(int waveId) async {
    // 设置输入框初始值为当前 shipCount 的值
    _controller.text = shipCount.toString();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 禁止在外部点击关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('送货单数量'),
          content: TextField(
            style: Theme.of(context).textTheme.titleLarge,
            controller: _controller,
            decoration: const InputDecoration(hintText: '请输入数量'),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () async {
                final int? newCount = int.tryParse(_controller.text);
                if (newCount != null) {
                  // 调用http服务
                  final response = await httpClient(
                    uri: Uri.parse('$httpHost/app/order/wave/shipCount/update'),
                    body: {'shipCount': newCount, 'waveId': waveId},
                    method: "POST",
                  );

                  if (response.isSuccess) {
                    // 更新内部状态，关闭对话框
                    setState(() {
                      shipCount = newCount;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                            '更新成功',
                          ),
                          backgroundColor: Colors.green),
                    );
                  } else {
                    String msg = response.message;
                    // 处理错误情况
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(msg), backgroundColor: Colors.red));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

//-----------------------------------列表------------------------

// 从服务器获取波次数据的函数
Future<List<Wave>> fetchWavesByDate(DateTime date) async {
  final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
  final response = await httpClient(
      uri: Uri.parse('$httpHost/app/order/wave/list?date=$formattedDate'),
      method: "GET");

  if (response.isSuccess) {
    return waveListFromJson(response.data).wave;
  } else {
    throw Exception(response.message);
  }
}
