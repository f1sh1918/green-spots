import 'package:flutter/material.dart';
import 'package:spots/user/community_service.dart';
import 'package:spots/user/profile_dialog.dart';
import 'package:spots/user/user_avatar.dart';

class CommunityRankingCard extends StatefulWidget {
  final String? token;

  const CommunityRankingCard({super.key, this.token});

  @override
  State<CommunityRankingCard> createState() => _CommunityRankingCardState();
}

class _CommunityRankingCardState extends State<CommunityRankingCard> {
  final _service = CommunityService();
  List<RankingEntry>? _entries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _service.fetchRanking(token: widget.token);
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) setState(() => _entries = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_entries == null || _entries!.isEmpty)
                  ? const Center(
                      child: Text(
                        'Noch keine Einträge.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries!.length,
                      itemBuilder: (context, index) {
                        final entry = _entries![index];
                        return _RankingTile(
                          rank: index + 1,
                          entry: entry,
                          onTap: () => showProfileDialog(
                            context,
                            userId: entry.userId,
                            token: widget.token,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final RankingEntry entry;
  final VoidCallback onTap;

  const _RankingTile({
    required this.rank,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColors = [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 28,
              child: isTop3
                  ? Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: rankColors[rank - 1],
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 8),
            UserAvatar(imageUrl: entry.avatarUrl, radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Spots
            Icon(Icons.park_outlined, size: 14, color: Colors.green[600]),
            const SizedBox(width: 3),
            Text(
              '${entry.spotCount}',
              style: TextStyle(fontSize: 12, color: Colors.green[700]),
            ),
            const SizedBox(width: 8),
            // Comments
            Icon(
              Icons.chat_bubble_outline,
              size: 14,
              color: Colors.blueGrey[400],
            ),
            const SizedBox(width: 3),
            Text(
              '${entry.commentCount}',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
