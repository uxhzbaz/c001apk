// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pages/home/return_top_controller.dart';
import '../../pages/search/search_order_controller.dart';
import '../../pages/search/search_result_content.dart';
import '../../utils/device_util.dart';
import '../../utils/extensions.dart';

enum SearchContentType { FEED, APP, GAME, TOPIC, PRODUCT, USER }

enum SearchMenuType { Type, Sort }

enum SearchType {
  ALL,
  FEED,
  ARTICLE,
  COOLPIC,
  COMMENT,
  RATING,
  ANSWER,
  QUESTION,
  VOTE,
}
extension SearchTypeExt on SearchType {
  String get displayName {
    switch (this) {
      case SearchType.ALL: return '全部';
      case SearchType.FEED: return '动态';
      case SearchType.ARTICLE: return '文章';
      case SearchType.COOLPIC: return '酷图';
      case SearchType.COMMENT: return '评论';
      case SearchType.RATING: return '评分';
      case SearchType.ANSWER: return '回答';
      case SearchType.QUESTION: return '提问';
      case SearchType.VOTE: return '投票';
    }
  }
}
enum SearchSortType { DATELINE, DEFAULT, HOT, REPLY, STRICT }
extension SearchSortTypeExt on SearchSortType {
  String get displayName {
    switch (this) {
      case SearchSortType.DATELINE: return '最新';
      case SearchSortType.DEFAULT: return '默认';
      case SearchSortType.HOT: return '热门';
      case SearchSortType.REPLY: return '回复';
      case SearchSortType.STRICT: return '严格';
    }
  }
}
class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}
extension SearchContentTypeExt on SearchContentType {
  String get displayName {
    switch (this) {
      case SearchContentType.FEED: return '动态';
      case SearchContentType.APP: return '应用';
      case SearchContentType.GAME: return '游戏';
      case SearchContentType.TOPIC: return '话题';
      case SearchContentType.PRODUCT: return '数码';
      case SearchContentType.USER: return '用户';
    }
  }
}
class _SearchResultPageState extends State<SearchResultPage>
    with TickerProviderStateMixin {
  final String _keyword = Get.parameters['keyword'] ?? '';
  final String? _title = Get.parameters['title'];
  final String? _pageType = Get.parameters['pageType'];
  final String? _pageParam = Get.parameters['pageParam'];

  late final TabController _tabController;
  final _shouldShowActionsStream = StreamController<bool>();

  late ReturnTopController _pageScrollController;
  late SearchOrderController _searchOrderController;

  late final String _random = DeviceUtil.randHexString(8);

  @override
  void initState() {
    super.initState();

    _pageScrollController = Get.put(ReturnTopController(),
        tag: '$_keyword$_title$_pageType$_pageParam$_random');
    _searchOrderController = Get.put(SearchOrderController(),
        tag: '$_keyword$_title$_pageType$_pageParam$_random');

    _tabController = TabController(
      vsync: this,
      length: _title.isNullOrEmpty ? SearchContentType.values.length : 1,
    );
    _tabController.addListener(() {
      _shouldShowActionsStream.add(_tabController.index == 0);
    });
  }

  @override
  void dispose() {
    _shouldShowActionsStream.close();
    _tabController.removeListener(() {});
    _tabController.dispose();
    Get.delete<ReturnTopController>(
      tag: '$_keyword$_title$_pageType$_pageParam$_random',
    );
    Get.delete<SearchOrderController>(
      tag: '$_keyword$_title$_pageType$_pageParam$_random',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: GestureDetector(
          onTap: () => Get.back(),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _keyword,
              style: const TextStyle(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: !_title.isNullOrEmpty
                ? Text(
                    '$_pageType: $_title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          ),
        ),
        actions: [
          StreamBuilder(
            initialData: true,
            stream: _shouldShowActionsStream.stream,
            builder: (_, snapshot) => snapshot.data == true
                ? PopupMenuButton(
                    onSelected: (SearchMenuType item) {
                      switch (item) {
                        case SearchMenuType.Type:
                          _showPopupMenu(isSearchType: true);
                          break;
                        case SearchMenuType.Sort:
                          _showPopupMenu(isSearchSortType: true);
                          break;
                      }
                    },
                    itemBuilder: (context) => SearchMenuType.values
                        .map((item) => PopupMenuItem<SearchMenuType>(
                              value: item,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(item == SearchMenuType.Type ? '类型' : '排序'),
                                  ),
                                  const Icon(Icons.arrow_right)
                                ],
                              ),
                            ))
                        .toList(),
                  )
                : const SizedBox.shrink(),
          )
        ],
        bottom: _title.isNullOrEmpty
            ? TabBar(
                isScrollable: true,
                controller: _tabController,
                tabs: SearchContentType.values
    .map((type) => Tab(
          text: type.displayName,
        ))
    .toList(),
                onTap: (index) {
                  if (!_tabController.indexIsChanging) {
                    _pageScrollController.setIndex(index);
                  }
                },
              )
            : const PreferredSize(
                preferredSize: Size.zero,
                child: Divider(height: 1),
              ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _title.isNullOrEmpty
            ? SearchContentType.values
                .map((type) => SearchResultContent(
                      random: _random,
                      searchContentType: type,
                      keyword: _keyword,
                      title: _title,
                      pageType: _pageType,
                      pageParam: _pageParam,
                    ))
                .toList()
            : [
                SearchResultContent(
                  random: _random,
                  searchContentType: SearchContentType.FEED,
                  keyword: _keyword,
                  title: _title,
                  pageType: _pageType,
                  pageParam: _pageParam,
                )
              ],
      ),
    );
  }

  void _showPopupMenu({
    bool isSearchType = false,
    bool isSearchSortType = false,
  }) async {
    final screenSize = MediaQuery.of(context).size;
    await showMenu(
      initialValue: isSearchType
          ? _searchOrderController.searchType.value
          : isSearchSortType
              ? _searchOrderController.searchSortType.value
              : null,
      context: context,
      position:
          RelativeRect.fromLTRB(screenSize.width, 0, 0, screenSize.height),
      items: isSearchType
    ? SearchType.values
        .map((type) => PopupMenuItem(value: type, child: Text(type.displayName)))
        .toList()
    : SearchSortType.values
        .map((type) => PopupMenuItem(value: type, child: Text(type.displayName)))
        .toList(),
      elevation: 8.0,
    ).then((value) {
      if (value != null) {
        if (value is SearchType) {
          _searchOrderController.setSearchType(value);
        }
        if (value is SearchSortType) {
          _searchOrderController.setSearchSortType(value);
        }
      }
    });
  }
}