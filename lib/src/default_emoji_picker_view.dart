import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/src/skin_tone_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Default EmojiPicker Implementation
class DefaultEmojiPickerView extends EmojiPickerBuilder {
  /// Constructor
  DefaultEmojiPickerView(Config config, EmojiViewState state)
      : super(config, state);

  @override
  _DefaultEmojiPickerViewState createState() => _DefaultEmojiPickerViewState();
}

class _DefaultEmojiPickerViewState extends State<DefaultEmojiPickerView>
    with SingleTickerProviderStateMixin, SkinToneOverlayStateMixin {
  final double _tabBarHeight = 46;
  List<Emoji> filterEmojiEntities = [];
  late PageController _pageController;
  Category? selectedCategory = Category.RECENT;
  bool hasResults = true;
  late TabController _tabController;
  late final _scrollController = ScrollController();

  late final _utils = EmojiPickerUtils();

  @override
  void initState() {
    var initCategory = widget.state.categoryEmoji.indexWhere(
        (element) => element.category == widget.config.initCategory);
    if (initCategory == -1) {
      initCategory = 0;
    }
    _tabController = TabController(
        initialIndex: initCategory,
        length: widget.state.categoryEmoji.length,
        vsync: this);
    _pageController = PageController(initialPage: initCategory)
      ..addListener(closeSkinToneOverlay);
    _scrollController.addListener(closeSkinToneOverlay);
    super.initState();
  }

  @override
  void dispose() {
    closeSkinToneOverlay();
    _pageController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emojiSize = widget.config.getEmojiSize(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                clipBehavior: Clip.antiAlias,
                onChanged: (value) async {
                  if (value.trim().isEmpty) {
                    filterEmojiEntities = [];
                    _pageController = PageController(initialPage: 0)..addListener(closeSkinToneOverlay);
                    selectedCategory = Category.RECENT;
                    if(mounted)setState(() {});
                  } else {
                    filterEmojiEntities = await EmojiPickerUtils()
                        .searchEmoji(value, defaultEmojiSet);
                    if(filterEmojiEntities.isEmpty){
                      hasResults = false;
                    }else{
                      hasResults = true;
                    }
                    selectedCategory = Category.SEARCH;
                  }
                  if (mounted) setState(() {});
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF90749B)),
                  filled: true,
                  hintText: "Search Emoji",
                  hintStyle: const TextStyle(
                    color: Color(0xFF90749B),
                    fontSize: 17,
                    fontFamily: 'SF Pro Text',
                    fontWeight: FontWeight.w400,
                    height: 0.07,
                  ),
                  fillColor: Colors.black26,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 16),
             Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                selectedCategory!.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF5F5E5F),
                  fontSize: 12,
                  fontFamily: 'SF Pro Text',
                  fontWeight: FontWeight.w600,
                  height: 0.10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: EmojiContainer(
                color: Colors.transparent,
                buttonMode: widget.config.buttonMode,
                child: !hasResults&&filterEmojiEntities.isEmpty?const Center(
                  child: Text(
                    'No Result',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ):filterEmojiEntities.isNotEmpty
                    ? GridView.count(
                        scrollDirection: Axis.vertical,
                        controller: _scrollController,
                        primary: false,
                        padding: widget.config.gridPadding,
                        crossAxisCount: widget.config.columns,
                        mainAxisSpacing: widget.config.verticalSpacing,
                        crossAxisSpacing: widget.config.horizontalSpacing,
                        children: [
                            for (int i = 0;
                                i < filterEmojiEntities.length;
                                i++)
                              EmojiCell.fromConfig(
                                emoji: filterEmojiEntities[i],
                                emojiSize: emojiSize,
                                index: i,
                                onEmojiSelected: (category, emoji) {
                                  closeSkinToneOverlay();
                                  widget.state
                                      .onEmojiSelected(category, emoji);
                                },
                                onSkinToneDialogRequested:
                                    _openSkinToneDialog,
                                config: widget.config,
                              )
                          ])
                    : Column(
                        children: [
                          Flexible(
                            child: PageView.builder(
                              itemCount: widget.state.categoryEmoji.length,
                              controller: _pageController,
                              onPageChanged: (index) {
                                _tabController.animateTo(
                                  index,
                                  duration:
                                      widget.config.tabIndicatorAnimDuration,
                                );
                              },
                              itemBuilder: (context, index) => _buildPage(
                                  emojiSize,
                                  widget.state.categoryEmoji[index]),
                            ),
                          ),
                          Container(
                            color: Colors.white.withOpacity(0.2),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildTabBar(context),
                                ),
                                _buildBackspaceButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context) => SizedBox(
        height: _tabBarHeight,
        child: TabBar(
          labelColor: widget.config.iconColorSelected,
          indicatorColor: widget.config.indicatorColor,
          unselectedLabelColor: widget.config.iconColor,
          controller: _tabController,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.zero,
          onTap: (index) {
            closeSkinToneOverlay();
            _pageController.jumpToPage(index);
            selectedCategory = widget.state.categoryEmoji[index].category;
            if (mounted) setState(() {});
          },
          tabs: widget.state.categoryEmoji
              .asMap()
              .entries
              .map<Widget>(
                  (item) => _buildCategory(item.key, item.value.category))
              .toList(),
        ),
      );

  Widget _buildBackspaceButton() {
    if (widget.state.onBackspacePressed != null) {
      return Material(
        type: MaterialType.transparency,
        child: IconButton(
            padding: const EdgeInsets.only(bottom: 2),
            icon: Icon(
              Icons.backspace,
              color: widget.config.backspaceColor,
            ),
            onPressed: () {
              widget.state.onBackspacePressed!();
            }),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCategory(int index, Category category) {
    return Tab(
      icon: selectedCategory == category
          ? CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(
              widget.config.getIconForCategory(category),
                color: Colors.white,
            ))
          : Icon(
              widget.config.getIconForCategory(category),
            ),
    );
  }

  Widget _buildPage(double emojiSize, CategoryEmoji categoryEmoji) {
    // Display notice if recent has no entries yet
    if (categoryEmoji.category == Category.RECENT &&
        categoryEmoji.emoji.isEmpty) {
      return _buildNoRecent();
    }
    // Build page normally
    return GestureDetector(
      onTap: closeSkinToneOverlay,
      child: GridView.count(
          scrollDirection: Axis.vertical,
          controller: _scrollController,
          primary: false,
          padding: widget.config.gridPadding,
          crossAxisCount: widget.config.columns,
          mainAxisSpacing: widget.config.verticalSpacing,
          crossAxisSpacing: widget.config.horizontalSpacing,
          children: [
            for (int i = 0; i < categoryEmoji.emoji.length; i++)
              EmojiCell.fromConfig(
                emoji: categoryEmoji.emoji[i],
                emojiSize: emojiSize,
                categoryEmoji: categoryEmoji,
                index: i,
                onEmojiSelected: (category, emoji) {
                  closeSkinToneOverlay();
                  widget.state.onEmojiSelected(category, emoji);
                },
                onSkinToneDialogRequested: _openSkinToneDialog,
                config: widget.config,
              )
          ]),
    );
  }

  /// Build Widget for when no recent emoji are available
  Widget _buildNoRecent() {
    return Center(
      child: widget.config.noRecents,
    );
  }

  void _openSkinToneDialog(
    Emoji emoji,
    double emojiSize,
    CategoryEmoji? categoryEmoji,
    int index,
  ) {
    closeSkinToneOverlay();
    if (!emoji.hasSkinTone || !widget.config.enableSkinTones) {
      return;
    }
    showSkinToneOverlay(
        emoji,
        emojiSize,
        categoryEmoji,
        index,
        kSkinToneCount,
        widget.config,
        _scrollController.offset,
        _tabBarHeight,
        _utils,
        _onSkinTonedEmojiSelected);
  }

  void _onSkinTonedEmojiSelected(Category? category, Emoji emoji) {
    widget.state.onEmojiSelected(category, emoji);
    closeSkinToneOverlay();
  }
}
