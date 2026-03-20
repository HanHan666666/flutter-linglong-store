import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 搜索栏组件
///
/// 支持搜索输入、搜索建议和防抖处理
class SearchBar extends ConsumerStatefulWidget {
  /// 搜索提示文本
  final String? hintText;

  /// 初始搜索文本
  final String? initialText;

  /// 搜索回调
  final ValueChanged<String>? onSearch;

  /// 文本变化回调
  final ValueChanged<String>? onChanged;

  /// 清除按钮点击回调
  final VoidCallback? onClear;

  /// 搜索建议列表
  final List<String>? suggestions;

  /// 是否显示搜索建议
  final bool showSuggestions;

  /// 防抖延迟时间（毫秒）
  final int debounceDelay;

  /// 输入框焦点
  final FocusNode? focusNode;

  /// 输入框控制器
  final TextEditingController? controller;

  const SearchBar({
    super.key,
    this.hintText,
    this.initialText,
    this.onSearch,
    this.onChanged,
    this.onClear,
    this.suggestions,
    this.showSuggestions = true,
    this.debounceDelay = 300,
    this.focusNode,
    this.controller,
  });

  @override
  ConsumerState<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<SearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// 防抖定时器
  Timer? _debounceTimer;

  /// 当前输入文本
  String _inputText = '';

  /// 是否显示建议列表
  bool _showSuggestionList = false;

  /// 过滤后的建议列表
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialText ?? '');
    _focusNode = widget.focusNode ?? FocusNode();
    _inputText = _controller.text;

    // 监听焦点变化
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// 焦点变化处理
  void _onFocusChange() {
    if (_focusNode.hasFocus && _inputText.isNotEmpty && widget.showSuggestions) {
      setState(() {
        _showSuggestionList = true;
      });
    } else {
      // 延迟隐藏，以便点击建议项时能够响应
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _showSuggestionList = false;
          });
        }
      });
    }
  }

  /// 输入变化处理
  void _onInputChanged(String value) {
    setState(() {
      _inputText = value;
    });

    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 设置新的防抖定时器
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceDelay), () {
      widget.onChanged?.call(value);

      // 更新建议列表
      if (widget.showSuggestions && widget.suggestions != null) {
        _updateSuggestions(value);
      }
    });

    // 显示建议
    if (widget.showSuggestions && _focusNode.hasFocus) {
      setState(() {
        _showSuggestionList = true;
      });
    }
  }

  /// 更新建议列表
  ///
  /// 根据用户输入过滤搜索建议：
  /// - 空查询：显示所有建议
  /// - 非空查询：显示包含查询文本的建议（大小写不敏感）
  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = widget.suggestions ?? [];
      });
    } else {
      setState(() {
        _filteredSuggestions = (widget.suggestions ?? [])
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  /// 执行搜索
  void _performSearch(String query) {
    widget.onSearch?.call(query);
    _focusNode.unfocus();
    setState(() {
      _showSuggestionList = false;
    });
  }

  /// 清除输入
  void _clearInput() {
    _controller.clear();
    setState(() {
      _inputText = '';
    });
    widget.onClear?.call();
  }

  /// 选择建议项
  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _inputText = suggestion;
      _showSuggestionList = false;
    });
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hintText = widget.hintText ?? (l10n?.searchPlaceholder ?? '搜索应用...');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 搜索输入框
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(24),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onInputChanged,
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _inputText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearInput,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),

        // 搜索建议列表
        if (_showSuggestionList && _filteredSuggestions.isNotEmpty)
          _buildSuggestionsList(context),
      ],
    );
  }

  /// 构建建议列表
  Widget _buildSuggestionsList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _filteredSuggestions[index];
          return ListTile(
            title: Text(suggestion),
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }
}