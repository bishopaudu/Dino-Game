import 'package:flutter/material.dart';

import '../models/dino.dart';

/// Handles all physics simulation for the dino.
/// 
/// This is a pure function system — no state is stored here.
/// Call [update] every frame to simulate one timestep.
class PhysicsSystem {
  /// Gravity acceleration in pixels per second squared.
  /// Higher = faster fall. Tune this to feel good.
  static const double gravity = 1800;

  /// Initial upward velocity applied when the player jumps.
  /// Negative because screen Y increases downward.
  static const double jumpForce = -700;// pulls down faster when ducking

 static const double duckGravity = 3200;
  /// Updates the dino's physics for one frame.
  ///
  /// [dino]       - the player to update
  /// [groundY]    - the Y coordinate of the ground surface
  /// [dt]         - delta time in seconds (time since last frame)
  void update(Dino dino, double groundY, double dt) {
    // If the dino is in the air, apply gravity to velocity.
    // Gravity constantly accelerates the dino downward.
    // v = v₀ + a·t  (velocity += acceleration × time)
    if (!dino.isOnGround) {
            final g = dino.isDucking ? duckGravity : gravity;

      //dino.velocityY += gravity * dt;
            dino.velocityY += g * dt;

    }
  // Ground anchor depends on duck state
    final effectiveHeight = dino.isDucking ? dino.height * 0.5 : dino.height;
    //final groundLimit = groundY - effectiveHeight;
    // Apply velocity to position.
    // x = x₀ + v·t  (position += velocity × time)
    dino.y += dino.velocityY * dt;

    // Check if the dino has landed on the ground.
    // groundY is where the top of the dino should be when standing.
    //final groundLimit = groundY - dino.height;
        final groundLimit = groundY - effectiveHeight;

    if (dino.y >= groundLimit) {
      // Clamp to ground — don't let it sink below.
      dino.y = groundLimit;
      dino.velocityY = 0;
      dino.isOnGround = true;
    }
  }

  /// Makes the dino jump.
  /// 
  /// Only allowed if the dino is currently on the ground.
  /// This prevents double-jumping.
  void jump(Dino dino) {
     debugPrint('jump() called — isOnGround: ${dino.isOnGround}');
    if (dino.isOnGround) {
      dino.velocityY = jumpForce;  // Launch upward
      dino.isOnGround = false;      // Now airborne
    }
  }

    void startDuck(Dino dino) {
    dino.isDucking = true;
    // If mid-air, cancel upward velocity so dino drops fast
    if (!dino.isOnGround && dino.velocityY < 0) {
      dino.velocityY = 200; // small downward nudge
    }
  }

  void endDuck(Dino dino) {
    dino.isDucking = false;
  }
}