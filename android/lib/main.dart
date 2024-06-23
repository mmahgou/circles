import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/services.dart';

void main() {
  runApp(GameWidget(game: FallingCirclesGame()));
}

class FallingCirclesGame extends FlameGame with TapDetector, KeyboardEvents {
  final Random _random = Random();
  int score = 0;
  int highScore = 0;
  late Character character;
  late Timer spawnTimer;
  late SharedPreferences prefs;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load SharedPreferences to get high score
    prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;

    // Load the character sprite and set size
    character = Character()
      ..sprite = await loadSprite('character.png')
      ..size = Vector2(100, 100); // Set character size

    // Add character to the game
    add(character);

    // Load the sound effect
    await FlameAudio.audioCache.load('point.wav');

    // Initialize timer to spawn circles
    spawnTimer = Timer(1, repeat: true, onTick: addCircle);
    spawnTimer.start();
  }

  @override
  void onMount() {
    super.onMount();
    // Position character at bottom center of screen
    character.position = Vector2(size.x / 2 - character.size.x / 2, size.y - character.size.y - 10); // Adjust position
  }

  void addCircle() {
    // Randomly decide if the circle is red or green
    final x = _random.nextDouble() * size.x;
    final isRed = _random.nextBool();
    final circle = FallingCircle(
      Vector2(x, 0),
      isRed ? Colors.red : Colors.green, // Red or green circle
      isRed,
    );
    // Add the circle to the game
    add(circle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update the timer to spawn circles
    spawnTimer.update(dt);
    // Check for collisions between the character and the circles
    checkCollisions();
  }

  void checkCollisions() {
    // Iterate through all FallingCircle components and check for collisions with the character
    children.whereType<FallingCircle>().forEach((circle) {
      if (circle.toRect().overlaps(character.toRect())) {
        if (circle.isRed) {
          // If the circle is red, reset the game
          resetGame();
        } else {
          // If the circle is green, catch it and remove it
          catchCircle(circle);
        }
      }
    });
  }

  void catchCircle(FallingCircle circle) {
    // Increase the score, play a sound, update the high score, and remove the circle
    score++;
    playPointSound();
    updateHighScore();
    remove(circle);
  }

  void updateHighScore() async {
    // Update the high score if the current score is higher
    if (score > highScore) {
      highScore = score;
      await prefs.setInt('highScore', highScore);
    }
  }

  void resetGame() {
    // Reset the score and remove all falling circles
    score = 0;
    removeAll(children.whereType<FallingCircle>().toList());
  }

  void playPointSound() {
    // Play the point sound effect
    FlameAudio.play('point.wav');
  }

  @override
  void render(Canvas canvas) {
    // Clear the screen with a white color
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), whitePaint);

    super.render(canvas);

    // Show the score and high score on the screen
    TextPaint tp = TextPaint(
      style: TextStyle(
        color: BasicPalette.black.color,
        fontSize: 24.0,
      ),
    );
    tp.render(canvas, 'Score: $score', Vector2(10, 10));
    tp.render(canvas, 'High Score: $highScore', Vector2(10, 40));
  }

  @override
  void onTap() {
    // Move the character to right when the screen is tapped
    character.moveRight();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Handle keyboard inputs for moving the character left and right
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        character.moveLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        character.moveRight();
      }
    }
    return KeyEventResult.handled;
  }
}

class FallingCircle extends CircleComponent {
  final bool isRed;

  FallingCircle(Vector2 position, Color color, this.isRed)
      : super(radius: 10, paint: Paint()..color = color) {
    this.position = position;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Move the circle down the screen
    position.y += 100 * dt;
  }
}

class Character extends SpriteComponent with HasGameRef<FallingCirclesGame> {
  Character() : super(size: Vector2(50, 50));

  void moveLeft() {
    // Move the character left ensuring it doesn't go off screen
    position.x -= 30;
    if (position.x < 0) {
      position.x = 0;
    }
  }

  void moveRight() {
    // Move the character right ensuring it doesn't go off screen
    position.x += 30;
    if (position.x + size.x > gameRef.size.x) {
      position.x = gameRef.size.x - size.x;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
  }
}
