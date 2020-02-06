pub const Tween = struct {
    tweenFn: fn (timeMs: f32, duration: f32, startValue: f32, changeInValue: f32) f32,
    startMs: u64,
    duration: f32,
    startValue: f32,
    changeInValue: f32,

    pub fn init(tweenFn: fn (timeMs: f32, duration: f32, startValue: f32, changeInValue: f32) f32, duration: f32, startValue: f32, changeInValue: f32) Tween {
        return Tween{
            .tweenFn = tweenFn,
            .startMs = 0,
            .duration = duration,
            .startValue = startValue,
            .changeInValue = changeInValue,
        };
    }

    pub fn linear(duration: f32, startValue: f32, changeInValue: f32) Tween {
        return Tween.init(linearFn, duration, startValue, changeInValue);
    }

    pub fn linearLimited(duration: f32, startValue: f32, changeInValue: f32) Tween {
        return Tween.init(linearLimitedFn, duration, startValue, changeInValue);
    }

    pub fn reset(self: *Tween, nowMs: u64) void {
        self.startMs = nowMs;
    }

    pub fn getValue(self: *const Tween, nowMs: u64) f32 {
        var time: u64 = undefined;
        _ = @subWithOverflow(u64, nowMs, self.startMs, &time);
        return self.tweenFn(@intToFloat(f32, time), self.duration, self.startValue, self.changeInValue);
    }
};

fn linearFn(timeMs: f32, duration: f32, startValue: f32, changeInValue: f32) f32 {
    return changeInValue * timeMs / duration + startValue;
}

/// Linear interpolation, until time is up
fn linearLimitedFn(timeMs: f32, duration: f32, startValue: f32, changeInValue: f32) f32 {
    if (timeMs < duration) {
        return changeInValue * timeMs / duration + startValue;
    } else {
        return startValue + changeInValue;
    }
}
