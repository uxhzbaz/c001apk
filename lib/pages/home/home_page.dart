import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pages/home/app/app_list_page.dart';
import '../../pages/home/feed/home_feed_page.dart';
import '../../pages/home/return_top_controller.dart';
import '../../pages/home/topic/home_topic_page.dart';
import '../../utils/utils.dart';

// ignore: constant_identifier_names
enum TabType { FOLLOW, APP, FEED, HOT, TOPIC, PRODUCT, COOLPIC, NONE }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final ReturnTopController _pageScrollController =
      Get.find<ReturnTopController>(tag: 'home');

  // 直接在 getter 中生成中文标签，确保每次 build 时都是最新
  List<Tab> get _tabList {
    final Map<TabType, String> tabNames = {
      TabType.FOLLOW: '关注',
      TabType.APP: '应用',
      TabType.FEED: '动态',
      TabType.HOT: '热门',
      TabType.TOPIC: '话题',
      TabType.PRODUCT: '数码',
      TabType.COOLPIC: '酷图',
      TabType.NONE: '',
    };
    var tabs = TabType.values.map((type) => Tab(text: tabNames[type]!)).toList();
    tabs.removeLast();
    if (!Platform.isAndroid) {
      tabs.removeAt(1);
    }
    return tabs;
  }

  final _pages = [
    const HomeFeedPage(tabType: TabType.FOLLOW),
    if (Platform.isAndroid) const AppListPage(),
    const HomeFeedPage(tabType: TabType.FEED),
    const HomeFeedPage(tabType: TabType.HOT),
    const HomeTopicPage(tabType: TabType.TOPIC),
    const HomeTopicPage(tabType: TabType.PRODUCT),
    const HomeFeedPage(tabType: TabType.COOLPIC),
  ];

  void scrollToTop(int index) {
    _pageScrollController.setIndex(Platform.isAndroid
        ? index
        : index == 0
            ? 0
            : index + 1);
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      vsync: this,
      initialIndex: Platform.isAndroid ? 2 : 1,
      length: _tabList.length,
    );

    _pageScrollController.index.listen((index) {
      if (index == 998) {
        scrollToTop(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TabBar(
          controller: _tabController,
          tabs: _tabList,
          isScrollable: true,
          onTap: (index) {
            if (!_tabController.indexIsChanging) {
              scrollToTop(index);
            }
          },
          tabAlignment: Utils.isWideLandscape(context)
              ? TabAlignment.center
              : TabAlignment.startOffset,
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/search'),
            icon: const Icon(Icons.search),
            tooltip: '搜索',
          )
        ],
      ),
      body: TabBarView(controller: _tabController, children: _pages),
    );
  }
}