import 'parenting_articles_how_to_teach.dart';
import 'parenting_articles_social_rules.dart';

/// مقالات إرشادية للأمهات وأولياء الأمور.
class ParentingArticle {
  const ParentingArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String id;
  final String title;
  final String subtitle;
  final String body;
}

ParentingArticle? parentingArticleById(String id) {
  for (final article in allParentingArticles) {
    if (article.id == id) return article;
  }
  return null;
}

const allParentingArticles = <ParentingArticle>[
  socialRulesArticle,
  teachEmotional0to2Article,
  discoverAptitudes0to2Article,
];
