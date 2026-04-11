import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots/user/community_provider.dart';
import 'package:spots/user/community_service.dart';
import 'package:spots/user/profile_dialog.dart';
import 'package:spots/user/user_avatar.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunityProvider>(context, listen: false).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.members == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = provider.members ?? [];

        return RefreshIndicator(
          onRefresh: () => provider.load(force: true),
          child: members.isEmpty
              ? const Center(child: Text('Keine Mitglieder gefunden.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: members.length,
                  itemBuilder: (context, index) =>
                      _MemberTile(rank: index + 1, entry: members[index]),
                ),
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final int rank;
  final RankingEntry entry;

  const _MemberTile({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColors = [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];

    return InkWell(
      onTap: () => showProfileDialog(
        context,
        userId: entry.userId,
        token: Provider.of<CommunityProvider>(context, listen: false).token,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: isTop3
                  ? Icon(
                      Icons.emoji_events,
                      size: 22,
                      color: rankColors[rank - 1],
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),
            UserAvatar(imageUrl: entry.avatarUrl, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.description != null &&
                      entry.description!.isNotEmpty)
                    Text(
                      entry.description!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.park_outlined, size: 14, color: Colors.green[600]),
            const SizedBox(width: 3),
            Text(
              '${entry.spotCount}',
              style: TextStyle(fontSize: 12, color: Colors.green[700]),
            ),
            const SizedBox(width: 8),
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
