import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteErrorPage extends StatelessWidget {
  final String location;

  const RouteErrorPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_off_rounded, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    '页面不存在',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '无法打开 $location。链接可能已经失效，也可能缺少打开该页面所需的数据。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('返回首页'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
