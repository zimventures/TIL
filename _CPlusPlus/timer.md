---
title: Timing with std::chrono
layout: default
order: 1
---


### "You may delay, but time will not."
##### - Benjamin Franklin

---

# The Time Problem
Tracking time. Seems like a simple enough task, right? Conceptually, all that is required is something like the following:

- Get the current time from a clock
- Determine how long it's been since the last clock snapshot
- Tell the user if the desired amount of time has elapsed
- Rinse & repeat every single cycle of the application

Traditionally, there have been some system libraries available to obtain time values, or even CPU cycles. It was up to the application to then convert those values into meaningful units (seconds, milliseconds, etc). Utilizing the `std::chrono` library, we can abstract away the underlying clock details and work with whatever time interval makes sense for us. 

# Time Deltas in Games
At the core of every game runtime is an application loop. The basic premise of these loops is to process inputs (user or network), execute systems (AI, collision detection, audio, etc), and render the scene. 

##### Example:
```c++
while(true) {
    // Handle inputs
    ProcessUserInput();
    DoNetworking();

    // Run systems
    AudioSystem::GetInstance().Update();
    PhysicsSystem::GetInstance().Update();
    
    // Draw
    pCurrentScene->Draw();
}
```
*NOTE: We'll ignore that this simple example is only running a single thread, thus completely negating any multi-core advantages.*

The problem with this basic example is that it's going *as fast as it can*. On modern computers, that loop is likely running thousands of times per second. Most game subsystems do not need to run with such frequency. Let's take the example a networking subsystem. Most client-server architectures operate somewhere in the realm of 30 to 60 times, or *ticks*, per second. Not only will this reduce the burden on the CPU for other tasks, but it provides a consistent message delivery flow with (hopefully) little to no variance in delivery rate. In the case of something like a physics engine, performing the world simulation is an expensive operation. Doing this every frame, in a complicated scene, would crush a CPU. 💥 Thankfully, good physics systems interpolate between simulations using a time delta for operations like collision detection. Which brings us to the topic of this post...timing! 

In order to run our subsystems on a predictable interval, we'll add a timer construct, with a target number of ticks per second. 

##### Loop with timer

{% highlight c++%}
auto timer = Timer(30);

while(true) {
    
    // Handle inputs
    ProcessUserInput();
    DoNetworking();

    // Run systems
    if (timer.Tick()) {
        AudioSystem::GetInstance().Update();
        PhysicsSystem::GetInstance().Update();
    }
    
    // Draw
    pCurrentScene->Draw();
}
{% endhighlight %}

As you can see, the `Timer` class is initialized to fire off a **tick** 30 times per second. The `timer` is updated every pass through our loop by invoking the `timer.Tick()`. When a **tick** has occurred, the `timer.Tick()` method will return `true`. Let's take a peek at the implementation of the `Timer` class to find out how it works. 

# Timer class implementation
The `Timer` class makes use of the `std::chrono` standard library. It uses the [`steady_clock`](https://en.cppreference.com/w/cpp/chrono/steady_clock) resource as its clock of choice. 

In order to provide the caller a notification of when a **tick** occurs, the `Timer` class will need to keep track of elapsed time. 

A few important questions will help guide our implementation: 
- Do we care about how much time has passed in between each game loop? (spoiler alert: we do)
- If we do care about elapsed time, what is the desired time frequency (seconds, milliseconds, microseconds, etc)?
- What happens when we're debugging?

## Time Frequency
As you've already guessed, we do care about the amount of time that has passed for each frame. Each game loop, the scene is drawn. There will be drawable entities within the scene that have an animation applied to them. We'll need to interpolate the animation, depending on how much time has elapsed from the start of the animation. The amount of time that has passed for each frame is important for this case. Being able to "ask" the `Timer` how long the previous loop took is a requirement. For our purposes, the time frequency of microseconds will give fine enough control and is easily scaled up to milliseconds or seconds, if need be. 

Internally, however, microseconds may NOT be fine grained enough for the purposes of the `Timer` class. What if a game loop cycle executes in LESS than a microsecond? If the `Timer` class only uses that as its time frequency, that passage of time will not be tracked. The way around this, is to use *whatever the native duration is for the underlying clock system*. In the case of the `steady_clock` facility, that happens to be nanoseconds, but we shouldn't care about it. We'll utilize some templating magic to abstract those details away. 

## Tracked durations and timestamps
The `Timer` class will track the following durations:
- Frame Delta: How much time has elapsed between the current and previous calls to `Tick()` 
- Tick Duration: The amount of elapsed time for the **current** tick
- Last Tick Duration: Total time elapsed for the previous tick (should equal `m_TargetTickDuration`)

We'll also track the following time snapshots, otherwise known as a `time_point` in `std::chrono` lingo.
- Tick Start Time: The timestamp that the current tick was started
- Last Frame Time: The timestamp that the previous frame started

## Abstracting Time
In order to not care about the underlying clock's frequency, we'll make use the `steady_clock::period` member variable. Per [the documentation](https://en.cppreference.com/w/cpp/chrono/steady_clock), this value is a `std::ratio` type representing the tick period of the clock, in seconds. With that in mind, here is how we'll define a "clock duration" for the `Timer` class. 
```c++
using clock_duration = std::chrono::duration<uint64_t, steady_clock::period>;
```

As previously noted, the caller (our game engine) will want to work with microseconds. We'll provide some helper methods to convert the underlying `clock_duration` type to that time interval. 
```c++
// Fetch the last frame's duration, in microseconds.
uint64_t GetDelta() { 
    return duration_cast<std::chrono::microseconds>(m_FrameDelta).count(); 
}

// Fetch the duration of the last tick, in microseconds.
uint64_t GetLastTick() { 
    return duration_cast<std::chrono::microseconds>(m_LastTickDuration).count(); 
}

// Fetch the last ticks duration, in seconds.
float GetLastTickAsSeconds() { 
    return (float)GetLastTick() / (float)std::micro::den; 
}

```

With the new template definitions, let's define some member variables to track the durations and time points:
```c++
...
private:
    // How many clock periods there are per tick. 
    clock_duration m_TargetTickDuration;

    // Time delta between the current Tick() call and the previous Tick() call. 
    clock_duration m_FrameDelta;

    // How long the current tick has been running for
    clock_duration m_TickDuration;

    // How long the last completed tick ran for
    clock_duration m_LastTickDuration;

    // The time which the current tick started
    steady_clock::time_point m_TickStartTime;

    // Timestamp of the last call to Tick()
    steady_clock::time_point m_LastFrameTime;
```

## Tick()
Each invocation of `Tick()` will perform the following operations: 
- Calculate the delta from the last frame
- If the timer isn't paused
    - Determine if a tick has occurred (current tick duration > desired ticks / second)
- Save the timestamp of the current frame

### Calculate the delta
Calculating the amount of time since the last frame is fairly easy. Simply subtract the current time point from the saved time point of the previous frame.

```c++
auto currentTime = steady_clock::now();
m_FrameDelta = currentTime - m_LastFrameTime;
```

But what if....the delta between the previous frame and the current frame is larger than our desired tick duration? That will definitely occur if we're doing some debugging with breakpoints or in the case of some unexpected lag spike on the system. To fix that, we'll simply normalize the delta to be equal to the desired duration for a single tick using `std::min()`. 

```c++
m_FrameDelta = std::min(m_FrameDelta, m_TargetTickDuration);
```

What was `m_TargetTickDuration`, you ask? We defined that in the `Timer` constructor as the duration of time that a single tick should take, as a `clock_duration`. Remember that we don't care what the underlying clock's period of measurement is. As such, we need to make use of the `steady_clock::period` parameter to convert our tick rate into a duration-per-tick that makes sense. 

*NOTE: `iTickRate` is the only required parameter for the `Timer` constructor.*
```c++
// Convert the ticks/second into whatever the clock duration/tick rate is
m_TargetTickDuration = clock_duration(static_cast<int>(((1.0f / iTickRate) * steady_clock::period::den)));
```

The `steady_clock::period::den` parameter is a integer-based ratio representing the number of units, per second, that the clock period tracks. The following table (taken from the `std::ratio` [documentation](https://en.cppreference.com/w/cpp/numeric/ratio/ratio)) shows the integer value for the various underlying types. 

|Type	|Definition|
|-------|----------|
|yocto	|std::ratio<1, 1000000000000000000000000>, if std::intmax_t can represent the denominator|
|zepto	|std::ratio<1, 1000000000000000000000>, if std::intmax_t can represent the denominator|
|atto	|std::ratio<1, 1000000000000000000>|
|femto	|std::ratio<1, 1000000000000000>|
|pico	|std::ratio<1, 1000000000000>|
|nano	|std::ratio<1, 1000000000>|
|micro	|std::ratio<1, 1000000>|
|milli	|std::ratio<1, 1000>|
|centi	|std::ratio<1, 100>|
|deci	|std::ratio<1, 10>|
|deca	|std::ratio<10, 1>|
|hecto	|std::ratio<100, 1>|
|kilo	|std::ratio<1000, 1>|
|mega	|std::ratio<1000000, 1>|
|giga	|std::ratio<1000000000, 1>|
|tera	|std::ratio<1000000000000, 1>|
|peta	|std::ratio<1000000000000000, 1>|
|exa	|std::ratio<1000000000000000000, 1>|
|zetta	|std::ratio<1000000000000000000000, 1>, if std::intmax_t can represent the numerator|
|yotta	|std::ratio<1000000000000000000000000, 1>, if std::intmax_t can represent the numerator|

Assuming that the `steady_clock` uses nanoseconds as its underlying type, that means it tracks 1,000,000,000 units per second. 

With the frame time now normalized, it's time to increment the current tick duration and check if it has exceeded our desired tick period.
```c++
// Only update the tick duration if we aren't paused.
if (IsPaused() == false) {

    // Increase the duration since the last tick.
    m_TickDuration += m_FrameDelta;

    // If the current period has gone past the amount of time each tick should take...then tick! 
    if (m_TickDuration >= m_TargetTickDuration) {
        bHasTicked = true;
        m_LastTickDuration = m_TickDuration;
        m_TickDuration = clock_duration::zero();
    }
}
```

The current tick duration is only incremented if the timer is *NOT* paused. The `bHasTicked` boolean is enabled, so that the caller knows the current tick has expired and it's time to do whatever must be done on a per-tick basis. For debug purposes, we save off the duration of the current tick (should equal, or less than 2 ticks periods). Lastly, the current tick duration is reset to zero using the special value `clock_duration::zero()`.

## Test program
A simple test program demonstrates the use of the timer within a dummy for-loop. 

```c++
#include <iostream>
#include "timer.h"

int main()
{
    auto timer = Timer(30);

    for (auto x = 0; x < 10000000; x++) {

        if (timer.Tick()) {
            std::cout << "tick: " << timer.GetLastTickAsSeconds() << " | " << timer.GetLastTick() << std::endl;
        }       
    }
}
```

You'll see from the output that `timer.Tick()` does indeed return `true` at the desired frequency.

```bash
tick: 0.033333 | 33333
tick: 0.033334 | 33334
tick: 0.033334 | 33334
tick: 0.033333 | 33333
tick: 0.033333 | 33333
tick: 0.033333 | 33333
tick: 0.033333 | 33333
tick: 0.033333 | 33333
tick: 0.033333 | 33333
```

And there you have it! A simple interface to track the passage of time that abstracts us away from needing to know the details of the system clock. 

# Full implementation

{% gist 7f0707da1c9134c9ca407a5a02016dc8 %}
