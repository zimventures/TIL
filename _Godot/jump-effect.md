---
title: Jump Effect
layout: default
order: 1
---


### "So many film makers are scared of visual effects - which is no crime."
##### - Peter Jackson

---

# Hello, Godot
"Gate Crasher" is a simple little game where the player steers a ship around a level, attempting to go through gates, without hitting the gate edges. It's a smaller sized game that is being used as a testing ground to learn the [Godot engine](https://godotengine.org/). The basic mechanics are in place and it's time to start adding some additional features - like a boost! Pressing a button on the controller should cause the players ship to jump forward by a specific amount. Jumping is cool and all, but having a nice visual effect to go along with the jump makes the experience feel much more lively. The two main components of the jump effect are a ship blur and particle burst. You can see both of these in action below.

#### Project Source Code <i class="fab fa-github p-1"></i>
The complete source for this project can be found in the `effect-boost` directory of my [Godot Tutorials repository on GitHub](https://github.com/zimventures/godot-tutorials/tree/main/effect-boost).

---------

<div class="row">

    <div class="col">
        <h3 class="display-3">Blur</h3>
        The first part of the effect is a blur. This is achieved by simply drawing the ship multiple times along the vector of the jump. Each one of the ship sprites that is drawn is set to slowly fade away at varying intervals.

        <h3 class="display-3">Particle Burst</h3>
        The blur effect on its own is pretty slick, but adding a particle system really makes the effect pop. A burst of particles along the jump vector really makes the jump feel fast. The particle velocity is set to be tangential to the jump vector in order to give a wave-like visual.
    </div>

    <div class="col">
        <img src='{{"/assets/images/Godot/godot-jump-effect-preview.gif" | relative_url}}'/>
    </div>
</div>

# Ship Basics
Let's start the project by creating a `PlayerShip` at the root of our scene. It'll be of the `Node2D` type. The `PlayerShip` needs a sprite so let's go ahead and add a `Sprite2D` child object, which we'll call `ShipSprite`. Add a script to the `PlayerShip` object: `PlayerShip.gd`

### Movement Logic

Your first version of `PlayerShip.gd` will look like the following:
```python
extends Node2D

func _process(delta):

	# Calculate the new ship velocity
	var velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Only update the position and rotation if the velocity changed
	if velocity.is_zero_approx() == false:
		velocity *= 500
		position += velocity * delta
		rotation = velocity.angle() + deg_to_rad(90)

	# Clamp the position to the screen size
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)
```

Nothing fancy here. We're pulling data from the controller thumb-stick in order to move the ship object around on the screen. Additionally, the position is clamped to the screen so that the ship never leaves the viewable area.

### Jump Logic
In order to make the ship "jump" we'll check for the "Y" button to be pressed on the controller and then advance the ship 100 pixels on the angle it's currently pointing at.

To start, let's check if the button is pressed, and then call a new function, `jump()` which we'll cook up shortly.
```gdscript

func _process(delta):
    # Is the player hitting the jump (boost) button?
    if Input.is_action_just_pressed('ui_select'):
        jump()
    # ...
```

The `jump()` function will be responsible for both handling the movement and rendering the visual effects. To start, the jump vector is calculated and then the ships position is moved 100 pixels along that vector.

```gdscript

func jump():
	"""Handle all of the logic for moving the ship forward by 100 pixels."""
	var original_pos = position

    # Calculate the forward vector to jump on
	var jump_vector = Vector2.from_angle(rotation - deg_to_rad(90))
	position += jump_vector * 100

    # ...
```

# Blur Effect Logic
The first part of the jump effect is a blur. The effect is achieved by rendering the ship sprite multiple times along the jump vector. Each sprite will slowly fade away - we'll create a custom script to handle this.

### Sprite Fader Helper (`SpriteFader.gd`)
This is a helper script that will slowly fade out a sprite, based on how much time is left. The alpha value of the sprite directly correlates with the lifetime remaining. We'll use the `SpriteFader` class in the `jump()` function in the next section. Once the timer expires, the item will self-destruct.

```gdscript
extends Sprite2D

class_name SpriteFader

# Member variables
var timer: SceneTreeTimer = null
var lifetime: float

func _init(_lifetime: float):
	"""Constructor to save off the requested lifetime."""
	# Setup the timer
	lifetime = _lifetime

func _ready():
	"""Entering the scene - fire up the timer!"""
	timer = get_tree().create_timer(lifetime)
	timer.connect('timeout', _timer_expired)

func _process(delta):
	"""Set the alpha value for the sprite, based on how much time is left."""
	modulate.a = timer.time_left / lifetime

func _timer_expired():
	"""Timer has expired - clean up after ourself."""
	queue_free()
```

### Creating the 10 blur sprites
Now it's time for some fun - rendering a trail of sprites to serve as the blur effect!

The algorithm here is as follows:
- Walk from the original jump position to the jump destination in 10 even increments
- For each position, create a sprite that will fade out
  - Fade out amount is based on its position on the vector
  - Match the rotation and scale of the player ship
  - Add the fading sprite to the scene


```gdscript
# Time to spwan a trail.
# The maximum range value is the number of image copies to create.
for i in range(10, 0, -1):

    # Convert the range into floating point number. 0 - 1, inclusive.
    var factor = i / 10.0

    # Calculate the lifetime, in seconds, for the sprite
    # 0 is the shortest life, 0.5 is the longest life. The Factor
    # determines where in that range this particular sprite will be.
    var lifetime = lerpf(0, 0.5, factor)

    # Create the new sprite and set its texture, scale, and rotation
    # to match that of the player's ship sprite.
    var sprite = SpriteFader.new(lifetime)
    sprite.texture = $ShipSprite.texture
    sprite.scale = scale * $ShipSprite.scale
    sprite.rotation = rotation

    # The position of the stripe is somewhere between the original
    # jump location and the jump destination. Use the factor to determine
    # how far along that vector this particular sprite should go.
    sprite.position = lerp(original_pos, position, factor)

    # Dont' forget to add the sprite to the scene!
    get_parent().add_child(sprite)

```
# Particle System
The particle system is defined on a child node within the project: `JumpTrail`. A copy of the system is created each time the ship jumps. Watch the livestream below or fire up a copy of the project to see the settings that are used in order to achieve the desired particle system feel.

## Dynamic System Creation
Within the `play()` function we instantiate and setup a new particle system using the following logic.

```gdscript
# Create a copy of the particle effect so that we can
# have it running in multiple places at the same time
var particle_copy = $JumpTrail.duplicate()
particle_copy.global_position = global_position
particle_copy.global_rotation = global_rotation
particle_copy.emitting = true
get_parent().add_child(particle_copy)

# Sneaky way to have the particle system delete itself at the end of its lifetime
get_tree().create_timer(particle_copy.lifetime, false).connect('timeout', particle_copy.queue_free)
```

<div class="row">

    <div class="col">
        <h3 class="display-3">Conclusion</h3>
        And that's it! With a simple helper class (`SpriteFader`) and some basic linear interpolation, we've got a pretty sweet little jump effect that can be used (and reused) in various projects.
        If you found this useful, please toss a ⭐ on <a href="https://github.com/zimventures/godot-tutorials" _target="_blank">the repo</a>, or feel free to <a href="https://twitter.com/603zim" _target="_blank">drop me a comment</a>.
    </div>

    <div class="col">
        <img src='{{"/assets/images/Godot/gate-crasher-jump.gif" | relative_url}}'/>
    </div>
</div>

# Livestream
For those of you who loathe the whole reading thing, here is a livestream of the effect being coded up.

<div style="padding:56.25% 0 0 0;position:relative;"><iframe src="https://player.vimeo.com/video/855573055?h=be4e8b1fa3&amp;badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479" frameborder="0" allow="autoplay; fullscreen; picture-in-picture" style="position:absolute;top:0;left:0;width:100%;height:100%;" title="Ship Jump Effect in Godot"></iframe></div><script src="https://player.vimeo.com/api/player.js"></script>

-----------------------------
