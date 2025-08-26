class GameState {
  bool isTimeFrozen = false;
  bool isTimeSlowed = false;
  double timeFreezeRemaining = 0.0;
  double timeSlowRemaining = 0.0;
  
  int score = 0;
  int level = 1;
  int ballsRemaining = 1;
  
  void update(double dt) {
    if (isTimeFrozen) {
      timeFreezeRemaining -= dt;
      if (timeFreezeRemaining <= 0) {
        isTimeFrozen = false;
        timeFreezeRemaining = 0.0;
      }
    }
    
    if (isTimeSlowed) {
      timeSlowRemaining -= dt;
      if (timeSlowRemaining <= 0) {
        isTimeSlowed = false;
        timeSlowRemaining = 0.0;
      }
    }
  }
  
  void activateTimeFreeze(double duration) {
    isTimeFrozen = true;
    timeFreezeRemaining = duration;
  }
  
  void activateTimeSlow(double duration) {
    isTimeSlowed = true;
    timeSlowRemaining = duration;
  }
  
  double getTimeMultiplier() {
    if (isTimeFrozen) return 0.0;
    if (isTimeSlowed) return 0.3;
    return 1.0;
  }
  
  void activateTimeEffect(String effectType, double duration) {
    if (effectType == 'timeFreeze') {
      activateTimeFreeze(duration);
    } else if (effectType == 'timeSlow') {
      activateTimeSlow(duration);
    }
  }
  
  void reset() {
    isTimeFrozen = false;
    isTimeSlowed = false;
    timeFreezeRemaining = 0.0;
    timeSlowRemaining = 0.0;
    score = 0;
    level = 1;
    ballsRemaining = 1;
  }
}

enum BrickType {
  normal,
  explosive,
  time,
  teleport,
}

enum PowerUpType {
  timeFreeze,
  cloneBall,
  laserBall,
}