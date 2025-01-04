import 'package:flutter/material.dart';
import 'package:flutter_scankit_example/bottom_bar.dart';
import 'package:flutter_scankit_example/constants.dart';
import 'package:flutter_scankit_example/login.dart';
import 'package:flutter_scankit_example/my.dart';
import 'package:flutter_scankit_example/scan_general.dart';
import 'package:flutter_scankit_example/user_data.dart';
import 'package:flutter_scankit_example/user_role.dart';

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
    for (Role role in roles) {
      if (role.roleCode == jianhuoRoleCode ||
          role.roleCode == songhuoRoleCode ||
          role.roleType == 1) {
        itemRoles.add(role);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoleManager(itemRoles.isNotEmpty
          ? itemRoles[0]
          : Role(
              roleCode: "", roleName: "", roleType: 1, menuIcon: "")), // 初始化角色
      child: Consumer<RoleManager>(
        builder: (context, roleManager, child) {
          return Scaffold(
            appBar: AppBar(
              title: _currentIndex < itemRoles.length
                  ? Text(itemRoles[_currentIndex].roleName + "扫码",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green))
                  : const Text("我的"),
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
            body: _currentIndex < itemRoles.length
                ? ScanGeneralScreen()
                : MyScreen(user: widget.user),
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

  RoleManager(this._role);

  Role get role => _role;

  void updateRole(Role newRole) {
    _role = newRole;
    notifyListeners();
  }
}
