class WordList {
  static final List<String> validWords = [
    'about', 'above', 'abuse', 'actor', 'acute', 'admit', 'adopt', 'adult',
    'after', 'again', 'agent', 'agree', 'ahead', 'alarm', 'album', 'alert',
    'alike', 'alive', 'allow', 'alone', 'along', 'alter', 'among', 'anger',
    'angle', 'angry', 'apart', 'apple', 'apply', 'arena', 'argue', 'arise',
    'array', 'aside', 'asset', 'audio', 'audit', 'avoid', 'award', 'aware',
    // Add more words as needed
  ];

  static String getRandomWord() {
    validWords.shuffle();
    return validWords.first;
  }
}