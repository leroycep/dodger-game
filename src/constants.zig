pub const APP_NAME = "dodger";

pub const FRAME_TIME = 16666666;

pub const SCREEN_WIDTH = 640;
pub const SCREEN_HEIGHT = 480;

pub const PLAYER_SPEED = 4.0;
pub const PLAYER_JUMP_HEIGHT = 128.0;
pub const PLAYER_TIME_IN_AIR = 32.0;
pub const PLAYER_JUMP_VEL = (2 * PLAYER_JUMP_HEIGHT - 0.5 * GRAVITY * PLAYER_TIME_IN_AIR * PLAYER_TIME_IN_AIR) / PLAYER_TIME_IN_AIR;

pub const ENEMY_START_SCORE = 0.5;

pub const ENEMY_SPEED = 4;
pub const ENEMY_START_Y = -32;
pub const INITIAL_MAX_ENEMIES = 10;
pub const ENEMY_TICKS_ON_FLOOR = 30;
pub const ENEMY_TICKS_ON_FLOOR_VARIATION = 20; // Percentage, multiply int by 100 then divide by this, then divide by 100
pub const ENEMY_TURN_TWEEN_SPEED = 0.5;
pub const ENEMY_LANDING_TWEEN_DURATION = 100;
pub const ENEMY_LANDING_TWEEN_START_SCALE_Y = 0.1;

// Enemy Death Tween
pub const ENEMY_DEATH_TWEEN_DURATION = 70;
pub const ENEMY_DEATH_TWEEN_DURATION_TICKS = ENEMY_DEATH_TWEEN_DURATION / (FRAME_TIME / 1000000);
pub const ENEMY_DEATH_TWEEN_START_SCALE_X = 1;
pub const ENEMY_DEATH_TWEEN_CHANGE_SCALE_X = -1;

pub const GRAVITY = 2.0;
pub const MAX_VELOCITY = 10.0;

pub const NAME_MAX_LENGTH = 20;
