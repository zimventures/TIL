// DDA Algorithm ==============================================
// https://lodev.org/cgtutor/raycasting.html

function TileRayCastDebug(_x, _y, _rx, _ry, _map) {
	
	// _x, _y, _rx, _ry, and _map will be passed into the function	
	draw_text(0, 400, "Start Position: " + string(_x) + "," + string(_y));
	draw_text(0, 415, "Mouse position: " + string(_rx) + "," + string(_ry));

	// The assumption here is that tiles are always square!
	var _tile_size = tilemap_get_tile_width(_map);

	// Angle of the ray	
	var _rayDirectionX = _rx - _x;
	var _rayDirectionY = _ry - _y;
	var _rayLength = sqrt((_rayDirectionX * _rayDirectionX) + (_rayDirectionY * _rayDirectionY));
	draw_text(0, 0, "Ray Length: " + string(_rayLength));
	draw_text(0, 15, "Ray Direction: " + string(_rayDirectionX) + "," + string(_rayDirectionY));

	// Normalize the ray direciton
	var _rayDirectionXNorm = _rayDirectionX / _rayLength;
	var _rayDirectionYNorm = _rayDirectionY / _rayLength;
	draw_text(0, 30, "Ray Norm: " + string(_rayDirectionXNorm) + "," + string(_rayDirectionYNorm));

	// Compute the ray step size in each direction (in tiles)
	// 2 == 2 tiles, not 2 pixels
	var _rayStepSizeX = sqrt(1.0 + (_rayDirectionYNorm / _rayDirectionXNorm) * (_rayDirectionYNorm / _rayDirectionXNorm));
	var _rayStepSizeY = sqrt(1.0 + (_rayDirectionXNorm / _rayDirectionYNorm) * (_rayDirectionXNorm / _rayDirectionYNorm));	
	draw_text(0, 60, "Ray Step Size: " + string(_rayStepSizeX) + "," + string(_rayStepSizeY));	

	// Determines in which direction in the tile map the algorightm will step.
	// Left = -1 | Right = 1 | Up = -1 | Down = 1
	var _stepX, _stepY;

	// Tracks the overall length of the ray, in tile units
	var _rayLengthX, _rayLengthY;
	
	// These track the integer grid position that the algorithm is currently in.
	// Example values if going in the top left tile and going directly to the right: (0,0 -> 1,0 -> 2,0)
	var _mapCheckX = _x div _tile_size;
	var _mapCheckY = _y div _tile_size;	

	// Will become true IF a tile is found before the end of the line
	var tileFound = false;

	// The maximum distance of the ray, in tiles
	var maxDistance = _rayLength / _tile_size;

	// Algorithm's current distance, in tiles
	var currentDistance = 0.0;
	
	// Track the total number of steps that the algorithm took
	var _totalSteps = 0;

	// Setup the ray step direction (sign) and the initial ray length.
	// The initial ray length isn't 0 because it's snapped to the AABB of each tile
	if(_rayDirectionXNorm < 0) {
		_stepX = -1;
		_rayLengthX = (_x - (_mapCheckX * _tile_size)) / _tile_size * _rayStepSizeX;	
	} else {
		_stepX = 1;
		_rayLengthX = (((_mapCheckX + 1) * _tile_size) - _x) / _tile_size *_rayStepSizeX;		
	}

	// Do the same for the Y-axis movement
	if(_rayDirectionYNorm < 0) {
		_stepY = -1;
		_rayLengthY = (_y - (_mapCheckY * _tile_size)) / _tile_size * _rayStepSizeY;	
	} else {
		_stepY = 1;
		_rayLengthY = (((_mapCheckY + 1) * _tile_size) - _y) / _tile_size *_rayStepSizeY;	
	}

	draw_text(0, 75, "Step Direction: " + string(_stepX) + "," + string(_stepY));
	
	// Start stepping!
	while(!tileFound && currentDistance < maxDistance) {
	
		// Walk along the shortest path
		if(_rayLengthX < _rayLengthY) {
			_mapCheckX += _stepX;
			
			currentDistance = _rayLengthX;			
			_rayLengthX += _rayStepSizeX;
		} else {
			_mapCheckY += _stepY;
			
			currentDistance = _rayLengthY;			
			_rayLengthY += _rayStepSizeY;
		}
	
		// Short circuit out if we've gone past _rx,_ry
		if(currentDistance >= maxDistance) {
			currentDistance = maxDistance;
			break;
		}
	
		// Draw a dot where the current step finished at.
		var _tmpX = _x + (_rayDirectionXNorm * (currentDistance * _tile_size));
		var _tmpY = _y + (_rayDirectionYNorm * (currentDistance * _tile_size));
		draw_circle(_tmpX, _tmpY, 3, false);

		// Test tile at new test point
		if(tilemap_get(_map, _mapCheckX, _mapCheckY)) {
			tileFound = true;		
		} else {
			
			// Draw a "ghost tile" representing the tile that was tested against
			var _tmpX = _mapCheckX * _tile_size;
			var _tmpY = _mapCheckY * _tile_size;
			
			draw_set_color(c_white);
			draw_set_alpha(0.1);
			draw_rectangle(_tmpX, _tmpY, _tmpX + _tile_size, _tmpY + _tile_size, true);
			
			// Reset the alpha 
			draw_set_alpha(1.0);
		}
	
		_totalSteps++;
	}
	
	draw_text(0, 90, "Hit Tile: " + string(tileFound));
	draw_text(0, 105, "Current Distance: " + string(currentDistance));
	draw_text(0, 120, "Current Distance (px): " + string(round(currentDistance * _tile_size)));
	
	draw_text(0, 135, "Total Step Length: " + string(_rayLengthX) + "," + string(_rayLengthY));
	draw_text(0, 150, "Map Check: " + string(_mapCheckX) + "," + string(_mapCheckY));
	draw_text(0, 165, "Total Steps: " + string(_totalSteps));
	
	// Translate the line end point from tile space into pixel coordinate space
	var _endX = _x + (_rayDirectionXNorm * (currentDistance * _tile_size));
	var _endY = _y + (_rayDirectionYNorm * (currentDistance * _tile_size));

	if(tileFound) {
		draw_text(0, 180, "Collision Point: " + string(_endX) + "," + string(_endY));
		draw_circle(_endX, _endY, 10, true);
	} else {
		draw_text(0, 180, "Collision Point: N/A");
	}

	draw_line(_x, _y, _endX, _endY);
	
	return {
		Found: tileFound,
		X: _endX,
		Y: _endY,
		Length: round(currentDistance * _tile_size),
		TileX: _stepX,
		TileY: _stepY		
	}
} // end of TileRayCastDebug()


function TileRayCast(_x, _y, _rx, _ry, _map) {
		
	// The assumption here is that tiles are always square!
	var _tile_size = tilemap_get_tile_width(_map);

	// Angle of the ray	
	var _rayDirectionX = _rx - _x;
	var _rayDirectionY = _ry - _y;
	var _rayLength = sqrt((_rayDirectionX * _rayDirectionX) + (_rayDirectionY * _rayDirectionY));	

	// Normalize the ray direciton
	var _rayDirectionXNorm = _rayDirectionX / _rayLength;
	var _rayDirectionYNorm = _rayDirectionY / _rayLength;

	// Compute the ray step size in each direction (in tiles)
	// 2 == 2 tiles, not 2 pixels
	var _rayStepSizeX = sqrt(1.0 + (_rayDirectionYNorm / _rayDirectionXNorm) * (_rayDirectionYNorm / _rayDirectionXNorm));
	var _rayStepSizeY = sqrt(1.0 + (_rayDirectionXNorm / _rayDirectionYNorm) * (_rayDirectionXNorm / _rayDirectionYNorm));	

	// Determines in which direction in the tile map the algorightm will step.
	// Left = -1 | Right = 1 | Up = -1 | Down = 1
	var _stepX, _stepY;

	// Tracks the overall length of the ray, in tile units
	var _rayLengthX, _rayLengthY;
	
	// These track the integer grid position that the algorithm is currently in.
	// Example values if going in the top left tile and going directly to the right: (0,0 -> 1,0 -> 2,0)
	var _mapCheckX = _x div _tile_size;
	var _mapCheckY = _y div _tile_size;
	
	// Setup the ray step direction (sign) and the initial ray length.
	// The initial ray length isn't 0 because it's snapped to the AABB of each tile
	if(_rayDirectionXNorm < 0) {
		_stepX = -1;
		_rayLengthX = (_x - (_mapCheckX * _tile_size)) / _tile_size * _rayStepSizeX;	
	} else {
		_stepX = 1;
		_rayLengthX = (((_mapCheckX + 1) * _tile_size) - _x) / _tile_size *_rayStepSizeX;		
	}

	// Do the same for the Y-axis movement
	if(_rayDirectionYNorm < 0) {
		_stepY = -1;
		_rayLengthY = (_y - (_mapCheckY * _tile_size)) / _tile_size * _rayStepSizeY;	
	} else {
		_stepY = 1;
		_rayLengthY = (((_mapCheckY + 1) * _tile_size) - _y) / _tile_size *_rayStepSizeY;	
	}

	// Will become true IF a tile is found before the end of the line
	var tileFound = false;

	// The maximum distance of the ray, in tiles
	var maxDistance = _rayLength / _tile_size;

	// Algorithm's current distance, in tiles
	var currentDistance = 0.0;	

	// Start stepping!
	while(!tileFound && currentDistance < maxDistance) {
	
		// Walk along the shortest path
		if(_rayLengthX < _rayLengthY) {
			_mapCheckX += _stepX;
			
			currentDistance = _rayLengthX;			
			_rayLengthX += _rayStepSizeX;
		} else {
			_mapCheckY += _stepY;
			
			currentDistance = _rayLengthY;			
			_rayLengthY += _rayStepSizeY;
		}
	
		// Short circuit out if we've gone past _rx,_ry
		if(currentDistance >= maxDistance) {
			currentDistance = maxDistance;
			break;
		}		

		// Test tile at new test point
		if(tilemap_get(_map, _mapCheckX, _mapCheckY)) {
			tileFound = true;		
		}	
	}	
	
	// Translate the line end point from tile space into pixel coordinate space
	var _endX = _x + (_rayDirectionXNorm * (currentDistance * _tile_size));
	var _endY = _y + (_rayDirectionYNorm * (currentDistance * _tile_size));	
	
	return {
		Found: tileFound,
		X: _endX,
		Y: _endY,
		Length: round(currentDistance * _tile_size),
		TileX: _stepX,
		TileY: _stepY		
	}
} // end of TileRayCast()
