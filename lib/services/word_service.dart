import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as parser;

class WordService {
  static const String _nytUrl = 'https://www.nytimes.com/games/wordle/index.html';
  
  static Future<String> getTodaysWord() async {
    try {
      final response = await http.get(Uri.parse(_nytUrl));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final scripts = document.getElementsByTagName('script');
        
        // Find the script that contains the game data
        for (var script in scripts) {
          if (script.text.contains('gameData')) {
            // Extract the solution from game data
            final regex = RegExp(r'"solution":"(\w+)"');
            final match = regex.firstMatch(script.text);
            if (match != null) {
              return match.group(1)!.toUpperCase();
            }
          }
        }
      }
      throw Exception('Failed to get today\'s word');
    } catch (e) {
      throw Exception('Error getting today\'s word: $e');
    }
  }

  static Future<List<String>> getWordList() async {
    try {
      // You can either fetch from a local JSON file or an API
      final response = await http.get(
        Uri.parse('https://gist.githubusercontent.com/cfreshman/cdcdf777450c5b5301e439061d29694c/raw/de1df631b45492e0974f7affe266ec36fed736eb/wordle-allowed-guesses.txt'),
      );

      if (response.statusCode == 200) {
        return LineSplitter.split(response.body).toList();
      }
      throw Exception('Failed to load word list');
    } catch (e) {
      throw Exception('Error loading word list: $e');
    }
  }
}
