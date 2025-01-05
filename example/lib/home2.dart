import 'package:flutter/material.dart';
import 'package:flutter_scankit_example/bottom_bar.dart';
import 'package:flutter_scankit_example/constants.dart';
import 'package:flutter_scankit_example/login.dart';
import 'package:flutter_scankit_example/my.dart';
import 'package:flutter_scankit_example/scan_general.dart';
import 'package:flutter_scankit_example/scan_shipper.dart';
import 'package:flutter_scankit_example/user_data.dart';
import 'package:flutter_scankit_example/user_role.dart';
import 'package:flutter_scankit_example/wave_list.dart';

import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class Home2Page extends StatefulWidget {
  final User user;

  Home2Page({required this.user});

  @override
  _Home2PageState createState() => _Home2PageState();
}

class _Home2PageState extends State<Home2Page> {
  int _currentIndex = 0;
  late List<Role> roles;
  late List<Role> itemRoles = [];

  @override
  void initState() {
    super.initState();
    roles = widget.user.roleInfoList!.cast<Role>();

    itemRoles = generateItemRole();
  }

  /**
   * item顺序： 拣货、送货、其他type=1的扫码、其他item、我的
   */
  List<Role> generateItemRole() {
    // 创建一个空的列表来存储最终的 itemRoles
    List<Role> resultRoles = [];

    // 用于记录唯一的 roleCode
    Set<String> uniqueRoleCodes = {};

    // 创建一个列表来存储去重后的角色
    List<Role> uniqueRoles = [];

    // 去重角色并将不重复的角色添加到 uniqueRoles 列表中
    for (Role role in roles) {
      if (!uniqueRoleCodes.contains(role.roleCode)) {
        uniqueRoleCodes.add(role.roleCode);
        uniqueRoles.add(role);
      }
    }

    // 先将含有 jianhuoRoleCode 的角色添加到 itemRoles 中
    for (Role role in uniqueRoles) {
      if (role.roleCode == jianhuoRoleCode) {
        resultRoles.add(role);
      }
    }

    // 然后将含有 songhuoRoleCode 的角色添加到 itemRoles 中
    for (Role role in uniqueRoles) {
      if (role.roleCode == songhuoRoleCode) {
        resultRoles.add(role);
      }
    }

    // 最后，将其他 roleType 为 1 的角色添加到 itemRoles 中
    for (Role role in uniqueRoles) {
      if (role.roleCode != jianhuoRoleCode &&
          role.roleCode != songhuoRoleCode &&
          role.roleType == 1) {
        resultRoles.add(role);
      }
    }

    // 将其余角色添加到 itemRoles 中，确保不会重复
    for (Role role in uniqueRoles) {
      if (role.roleCode != jianhuoRoleCode &&
          role.roleCode != songhuoRoleCode &&
          role.roleType != 1) {
        resultRoles.add(role);
      }
    }

    // 返回 itemRoles，即按照上述顺序排列的最终列表
    return resultRoles;
  }

  Text _getAppBarTitle() {
    if (_currentIndex >= itemRoles.length) {
      return const Text(
        "我的",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    } else if (itemRoles[_currentIndex].roleCode == jianhuoRoleCode) {
      return const Text(
        "波次列表",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    } else if (itemRoles[_currentIndex].roleCode == songhuoRoleCode) {
      return const Text(
        "送货扫码",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    } else if (itemRoles[_currentIndex].roleType == 1) {
      return Text(
        itemRoles[_currentIndex].roleName + "扫码",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    } else {
      return const Text(
        "我的",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }
  }

  Widget _getCurrentScreen() {
    if (_currentIndex >= itemRoles.length) {
      return MyScreen(user: widget.user);
    } else {
      dynamic data = {'role': itemRoles[_currentIndex]};

      if (itemRoles[_currentIndex].roleCode == jianhuoRoleCode) {
        return WaveListScreen(user: widget.user);
      } else if (itemRoles[_currentIndex].roleCode == songhuoRoleCode) {
        return ScanGeneralScreen(
          onCompletion: (String) {},
          data: data,
        );
      } else if (itemRoles[_currentIndex].roleType == 1) {
        return ScanGeneralScreen(
          onCompletion: (String) {},
          data: data,
        );
      } else {
        return ScanGeneralScreen(
          onCompletion: (String) {},
          data: data,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoleManager(
          itemRoles.isNotEmpty
              ? itemRoles[0]
              : Role(roleCode: "", roleName: "", roleType: 1, menuIcon: ""),
          {}), // 初始化角色
      child: Consumer<RoleManager>(
        builder: (context, roleManager, child) {
          return Scaffold(
            appBar: AppBar(
              title: _getAppBarTitle(),

              actions: _currentIndex >= itemRoles.length
                  ? <Widget>[
                      PopupMenuButton<int>(
                        onSelected: (item) => _onSelected(context, item),
                        itemBuilder: (context) => [
                          const PopupMenuItem<int>(
                            value: 0,
                            child: Text('登出'),
                          ),
                        ],
                      )
                    ]
                  : null, // 设置为 null 如果不需要 actions
            ),
            body: _getCurrentScreen(),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                Vibration.vibrate(duration: 10);
                setState(() {
                  _currentIndex = index;
                  // 更新RoleManager中的角色
                  if (index < itemRoles.length) {
                    roleManager.updateRole(itemRoles[index]);
                  }
                });
              },
              itemRoles: itemRoles,
            ),
          );
        },
      ),
    );
  }

  // 处理PopupMenuButton选项的选中事件
  void _onSelected(BuildContext context, int item) {
    switch (item) {
      case 0:
        logout(context);
        break;
      // 其他case...
    }
  }
}

class RoleManager with ChangeNotifier {
  Role _role;
  dynamic _data;

  RoleManager(this._role, this._data);

  Role get role => _role;

  dynamic get data => _data;

  void updateRole(Role newRole) {
    _role = newRole;
    notifyListeners();
  }

  void updateData(dynamic newData) {
    _data = newData;
    notifyListeners();
  }
}
