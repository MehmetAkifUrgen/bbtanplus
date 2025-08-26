import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class ParticleEffects {
  static ParticleSystemComponent createBrickBreakEffect(Vector2 position) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 15,
        lifespan: 1.0,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 200),
          speed: Vector2(
            (Random().nextDouble() - 0.5) * 200,
            -Random().nextDouble() * 100 - 50,
          ),
          position: position.clone(),
          child: CircleParticle(
            radius: Random().nextDouble() * 3 + 1,
            paint: Paint()..color = Colors.orange.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  static ParticleSystemComponent createExplosionEffect(Vector2 position) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 25,
        lifespan: 1.5,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 150),
          speed: Vector2(
            (Random().nextDouble() - 0.5) * 300,
            -Random().nextDouble() * 150 - 75,
          ),
          position: position.clone(),
          child: CircleParticle(
            radius: Random().nextDouble() * 4 + 2,
            paint: Paint()..color = Colors.red.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  static ParticleSystemComponent createPowerUpEffect(Vector2 position, Color color) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 10,
        lifespan: 0.8,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, -50),
          speed: Vector2(
            (Random().nextDouble() - 0.5) * 100,
            -Random().nextDouble() * 50 - 25,
          ),
          position: position.clone(),
          child: CircleParticle(
            radius: Random().nextDouble() * 2 + 1,
            paint: Paint()..color = color.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  static ParticleSystemComponent createTrailEffect(Vector2 position, Color color) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 5,
        lifespan: 0.3,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2.zero(),
          speed: Vector2(
            (Random().nextDouble() - 0.5) * 20,
            (Random().nextDouble() - 0.5) * 20,
          ),
          position: position.clone(),
          child: CircleParticle(
            radius: Random().nextDouble() * 1.5 + 0.5,
            paint: Paint()..color = color.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  static ParticleSystemComponent createTimeSlowEffect(Vector2 position) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 2.0,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2.zero(),
          speed: Vector2(
            (Random().nextDouble() - 0.5) * 50,
            -Random().nextDouble() * 25,
          ),
          position: position.clone(),
          child: CircleParticle(
            radius: Random().nextDouble() * 2 + 1,
            paint: Paint()..color = Colors.purple.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}