
// stories_view_screen.dart
import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:user_auth_crudd10/model/Story.dart';

class StoriesViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  StoriesViewScreen({required this.stories, required this.initialIndex});

  @override
  _StoriesViewScreenState createState() => _StoriesViewScreenState();
}

class _StoriesViewScreenState extends State<StoriesViewScreen> {
  final storyController = StoryController();
  List<StoryItem> storyItems = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  void _loadStories() {
    for (var story in widget.stories) {
      if (story.videoUrl != null) {
        storyItems.add(StoryItem.pageVideo(
          story.videoUrl!,
          controller: storyController,
        ));
      } else {
        storyItems.add(StoryItem.pageImage(
          url: story.imageUrl,
          controller: storyController,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoryView(
        storyItems: storyItems,
        controller: storyController,
        onComplete: () => Navigator.pop(context),
        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    storyController.dispose();
    super.dispose();
  }
}

// stories_preview.dart
class StoriesPreview extends StatelessWidget {
  final List<Story> stories;

  const StoriesPreview({Key? key, required this.stories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoriesViewScreen(
                    stories: stories,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Container(
              width: 70,
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(2),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(story.imageUrl),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}