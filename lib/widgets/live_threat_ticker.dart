import 'package:flutter/material.dart';
import '../models/threat_event.dart';

/// Scrolling horizontal intelligence ticker showing real-time threat events.
/// Appears at the top of the map like a breaking-news bar.
class LiveThreatTicker extends StatefulWidget {
  final List<ThreatEvent> events;

  const LiveThreatTicker({super.key, required this.events});

  @override
  State<LiveThreatTicker> createState() => _LiveThreatTickerState();
}

class _LiveThreatTickerState extends State<LiveThreatTicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      _scrollController
          .animateTo(
        maxScroll,
        duration: Duration(seconds: (maxScroll / 30).round().clamp(10, 120)),
        curve: Curves.linear,
      )
          .then((_) {
        if (!mounted) return;
        _scrollController.jumpTo(0);
        _startAutoScroll();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // "LIVE" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.red.withOpacity(0.9),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 6),
                SizedBox(width: 4),
                Text(
                  'INTEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Scrolling events
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.events.length,
              itemBuilder: (context, index) {
                return _buildTickerItem(widget.events[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTickerItem(ThreatEvent event) {
    final age = DateTime.now().difference(event.timestamp);
    final ageStr = age.inMinutes < 60
        ? '${age.inMinutes}m ago'
        : '${age.inHours}h ago';

    final severityColor = event.severityScore >= 8
        ? Colors.red
        : event.severityScore >= 5
            ? Colors.orange
            : Colors.amber;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(event.sourceFlag, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            event.type.name.toUpperCase(),
            style: TextStyle(
              color: severityColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            event.headline.length > 40
                ? '${event.headline.substring(0, 40)}...'
                : event.headline,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 9,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            ageStr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 8,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
