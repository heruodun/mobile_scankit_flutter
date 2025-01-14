import 'package:flutter/material.dart';
import 'package:flutter_scankit_example/constants.dart';
import 'package:flutter_scankit_example/user_role.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<Role> itemRoles;

  BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.itemRoles,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // 确保底部导航栏为固定类型
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.purple, // 选中项的颜色
      unselectedItemColor: Colors.black54, // 未选中项的颜色
      items: generate(),
    );
  }

  List<BottomNavigationBarItem> generate() {
    return List.generate(itemRoles.length + 1, (index) {
      //item顺序： 拣货、送货、其他type=1的扫码、其他item、我的
      if (index < itemRoles.length) {
        return BottomNavigationBarItem(
          icon: const Icon(Icons.camera),
          label: itemRoles[index].roleName,
        );
      } else {
        return const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "我的",
        );
      }
    });
  }
}
