/*
The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (!isServer) exitWith {};

APR_Pickup_Rope = {
  params["_player", "_heli"];
  if (isServer) then {

    if (_player getVariable["AR_Is_Rappelling", false]) exitWith {};

    // Find next available rappel anchor
    _rappelPoints = [_heli] call AR_Get_Heli_Rappel_Points;
    _rappelPointIndex = 0; {
      _rappellingPlayer = _heli getVariable["AR_Rappelling_Player_" + str _rappelPointIndex, objNull];
      if (isNull _rappellingPlayer) exitWith {};
      _rappelPointIndex = _rappelPointIndex + 1;
    }
    forEach _rappelPoints;

    // All rappel anchors are taken by other players. Hint player to try again.
    if (count _rappelPoints == _rappelPointIndex) exitWith {
      if (isPlayer _player) then {
        [
          ["All rappel anchors in use. Please try again.", false], "AR_Hint", _player
        ] call AR_RemoteExec;
      };
    };

    _heli setVariable["AR_Rappelling_Player_" + str _rappelPointIndex, _player];

    _player setVariable["AR_Is_Rappelling", true, true];

    // Start rappelling (client side)
    [_player, _heli, _rappelPoints select _rappelPointIndex] spawn APR_Client_Pickup_Rope;

    // Wait for player to finish rappeling before freeing up anchor
    [_player, _heli, _rappelPointIndex] spawn {
      params["_player", "_heli", "_rappelPointIndex"];
      while {
        true
      }
      do {
        if (!alive _player) exitWith {};
        if !(_player getVariable["AR_Is_Rappelling", false]) exitWith {};
        sleep 2;
      };
      _heli setVariable["AR_Rappelling_Player_" + str _rappelPointIndex, nil];
    };

  } else {
    [_this, "AR_Rappel_From_Heli", true] call AR_RemoteExecServer;
  };
};

APR_Client_Pickup_Rope = {
  params["_player", "_heli", "_rappelPoint"];
  if (local _player) then {
    [_player] orderGetIn false;
    moveOut _player;
    waitUntil {
      vehicle _player == _player
    };
    _rappelPointPosition = AGLtoASL(_heli modelToWorldVisual _rappelPoint);
    //_rappelPointPosition set[2, (_rappelPointPosition select 2) - 1];
    //_rappelPointPosition set[1, (_rappelPointPosition select 1) - ((((random 100) - 50)) / 25)];
    //_rappelPointPosition set[0, (_rappelPointPosition select 0) - ((((random 100) - 50)) / 25)];
    //_player setPosWorld _rappelPointPosition;

    _anchor = "Land_Can_V2_F"
    createVehicle _rappelPointPosition;
    _anchor allowDamage false;
    hideObject _anchor;
    [
      [_anchor], "AR_Hide_Object_Global"
    ] call AR_RemoteExecServer;
    _anchor attachTo[_heli, _rappelPoint];

    _rappelDevice = "B_static_AA_F"
    createVehicle position _player;
    //_rappelDevice setPosWorld _player;
    _rappelDevice allowDamage false;
    hideObject _rappelDevice;
    [
      [_rappelDevice], "AR_Hide_Object_Global"
    ] call AR_RemoteExecServer;

    [
      [_player, _rappelDevice, _anchor], "AR_Play_Rappelling_Sounds_Global"
    ] call AR_RemoteExecServer;

    _bottomRopeLength = 3;
    _bottomRope = ropeCreate[_rappelDevice, [-0.15, 0, 0], _bottomRopeLength];
    _bottomRope allowDamage false;
    _topRopeLength = (getPos _heli select 2) + 3;
    _topRope = ropeCreate[_rappelDevice, [0, 0.15, 0], _anchor, [0, 0, 0], _topRopeLength];
    _topRope allowDamage false;

    [_player] spawn AR_Enable_Rappelling_Animation_Client;

    _gravityAccelerationVec = [0, 0, -9.8];
    _velocityVec = [0, 0, 0];
    _lastTime = diag_tickTime;
    _lastPosition = AGLtoASL(_rappelDevice modelToWorldVisual[0, 0, 0]);
    _lookDirFreedom = 50;
    _dir = (random 360) + (_lookDirFreedom / 2);
    _dirSpinFactor = (((random 10) - 5) / 5) max 0.1;

    _ropeKeyDownHandler = -1;
    _ropeKeyUpHandler = -1;
    if (_player == player) then {

      _player setVariable["AR_DECEND_PRESSED", false];
      _player setVariable["AR_FAST_DECEND_PRESSED", false];
      _player setVariable["AR_RANDOM_DECEND_SPEED_ADJUSTMENT", 0];
      _player setVariable["AR_ASCEND_PRESSED", false];

      _ropeKeyDownHandler = (findDisplay 46) displayAddEventHandler["KeyDown", {
        if (_this select 1 in (actionKeys "MoveBack")) then {
          player setVariable["AR_DECEND_PRESSED", true];
        };
        if (_this select 1 in (actionKeys "Turbo")) then {
          player setVariable["AR_FAST_DECEND_PRESSED", true];
        };
        if (_this select 1 in (actionKeys "MoveForward")) then {
          player setVariable["AR_ASCEND_PRESSED", true];
        };
      }];

      _ropeKeyUpHandler = (findDisplay 46) displayAddEventHandler["KeyUp", {
        if (_this select 1 in (actionKeys "MoveBack")) then {
          player setVariable["AR_DECEND_PRESSED", false];
        };
        if (_this select 1 in (actionKeys "Turbo")) then {
          player setVariable["AR_FAST_DECEND_PRESSED", false];
        };
        if (_this select 1 in (actionKeys "MoveForward")) then {
          player setVariable["AR_ASCEND_PRESSED", false];
        };
      }];

    } else {

      _player setVariable["AR_DECEND_PRESSED", false];
      _player setVariable["AR_FAST_DECEND_PRESSED", false];
      _player setVariable["AR_RANDOM_DECEND_SPEED_ADJUSTMENT", (random 2) - 1];
      _player setVariable["AR_ASCEND_PRESSED", false];

      [_player] spawn {
        params["_player"];
        sleep 2;
        _player setVariable["AR_DECEND_PRESSED", true];
      };

    };

    // Cause player to fall from rope if heli is moving too fast
    _this spawn {
      params["_player", "_heli"];
      while {
        _player getVariable["AR_Is_Rappelling", false]
      }
      do {
        if (speed _heli > 150) then {
          if (isPlayer _player) then {
            ["Moving too fast! You've lost grip of the rope.", false] call AR_Hint;
          };
          [_player] call AR_Rappel_Detach_Action;
        };
        sleep 2;
      };
    };

    while {
      true
    }
    do {

      _currentTime = diag_tickTime;
      _timeSinceLastUpdate = _currentTime - _lastTime;
      _lastTime = _currentTime;
      if (_timeSinceLastUpdate > 1) then {
        _timeSinceLastUpdate = 0;
      };

      _environmentWindVelocity = wind;
      _playerWindVelocity = _velocityVec vectorMultiply - 1;
      _helicopterWindVelocity = (vectorUp _heli) vectorMultiply - 30;
      _totalWindVelocity = _environmentWindVelocity vectorAdd _playerWindVelocity vectorAdd _helicopterWindVelocity;
      _totalWindForce = _totalWindVelocity vectorMultiply(9.8 / 53);

      _accelerationVec = _gravityAccelerationVec vectorAdd _totalWindForce;
      _velocityVec = _velocityVec vectorAdd(_accelerationVec vectorMultiply _timeSinceLastUpdate);
      _newPosition = _lastPosition vectorAdd(_velocityVec vectorMultiply _timeSinceLastUpdate);

      _heliPos = AGLtoASL(_heli modelToWorldVisual _rappelPoint);

      if (_newPosition distance _heliPos > _topRopeLength) then {
        _newPosition = (_heliPos) vectorAdd((vectorNormalized((_heliPos) vectorFromTo _newPosition)) vectorMultiply _topRopeLength);
        _surfaceVector = (vectorNormalized(_newPosition vectorFromTo(_heliPos)));
        _velocityVec = _velocityVec vectorAdd((_surfaceVector vectorMultiply(_velocityVec vectorDotProduct _surfaceVector)) vectorMultiply - 1);
      };

      _rappelDevice setPosWorld(_lastPosition vectorAdd((_newPosition vectorDiff _lastPosition) vectorMultiply 6));

      _rappelDevice setVectorDir(vectorDir _player);
      _player setPosWorld[_newPosition select 0, _newPosition select 1, (_newPosition select 2) - 0.6];
      _player setVelocity[0, 0, 0];

      // Handle rappelling down rope
      if (_player getVariable["AR_DECEND_PRESSED", false]) then {
        _decendSpeedMetersPerSecond = 3.5;
        if (_player getVariable["AR_FAST_DECEND_PRESSED", false]) then {
          _decendSpeedMetersPerSecond = 5;
        };
        _decendSpeedMetersPerSecond = _decendSpeedMetersPerSecond + (_player getVariable["AR_RANDOM_DECEND_SPEED_ADJUSTMENT", 0]);
        _bottomRopeLength = _bottomRopeLength - (_timeSinceLastUpdate * _decendSpeedMetersPerSecond);
        _topRopeLength = _topRopeLength + (_timeSinceLastUpdate * _decendSpeedMetersPerSecond);
        ropeUnwind[_topRope, _decendSpeedMetersPerSecond, _topRopeLength];
        ropeUnwind[_bottomRope, _decendSpeedMetersPerSecond, _bottomRopeLength];
      } else {
        if (_player getVariable["AR_ASCEND_PRESSED", false]) then {
          _decendSpeedMetersPerSecond = 3.5;

          _decendSpeedMetersPerSecond = _decendSpeedMetersPerSecond + (_player getVariable["AR_RANDOM_DECEND_SPEED_ADJUSTMENT", 0]);
          _bottomRopeLength = _bottomRopeLength + (_timeSinceLastUpdate * _decendSpeedMetersPerSecond);
          _topRopeLength = _topRopeLength - (_timeSinceLastUpdate * _decendSpeedMetersPerSecond);
          ropeUnwind[_topRope, _decendSpeedMetersPerSecond, _topRopeLength];
          ropeUnwind[_bottomRope, _decendSpeedMetersPerSecond, _bottomRopeLength];
        };
      };

      // Fix player direction
      _dir = _dir + ((360 / 1000) * _dirSpinFactor);
      if (isPlayer _player) then {
        _currentDir = getDir _player;
        _minDir = (_dir - (_lookDirFreedom / 2)) mod 360;
        _maxDir = (_dir + (_lookDirFreedom / 2)) mod 360;
        _minDegreesToMax = 0;
        _minDegreesToMin = 0;
        if (_currentDir > _maxDir) then {
          _minDegreesToMax = (_currentDir - _maxDir) min(360 - _currentDir + _maxDir);
        };
        if (_currentDir < _maxDir) then {
          _minDegreesToMax = (_maxDir - _currentDir) min(360 - _maxDir + _currentDir);
        };
        if (_currentDir > _minDir) then {
          _minDegreesToMin = (_currentDir - _minDir) min(360 - _currentDir + _minDir);
        };
        if (_currentDir < _minDir) then {
          _minDegreesToMin = (_minDir - _currentDir) min(360 - _minDir + _currentDir);
        };
        if (_minDegreesToMin > _lookDirFreedom || _minDegreesToMax > _lookDirFreedom) then {
          if (_minDegreesToMin < _minDegreesToMax) then {
            _player setDir _minDir;
          } else {
            _player setDir _maxDir;
          };
        } else {
          _player setDir(_currentDir + ((360 / 1000) * _dirSpinFactor));
        };
      } else {
        _player setDir _dir;
      };

      _lastPosition = _newPosition;

      if (_player distance _heli < 3) then {
        _player moveInCargo _heli;
      };

      if (!alive _player || vehicle _player != _player || _bottomRopeLength <= 1 || _player getVariable["AR_Detach_Rope", false]) exitWith {};

      sleep 0.01;
    };

    if (_bottomRopeLength > 1 && alive _player && vehicle _player == _player) then {

      _playerStartASLIntersect = getPosASL _player;
      _playerEndASLIntersect = [_playerStartASLIntersect select 0, _playerStartASLIntersect select 1, (_playerStartASLIntersect select 2) - 5];
      _surfaces = lineIntersectsSurfaces[_playerStartASLIntersect, _playerEndASLIntersect, _player, objNull, true, 10];
      _intersectionASL = []; {
        scopeName "surfaceLoop";
        _intersectionObject = _x select 2;
        _objectFileName = str _intersectionObject;
        if ((_objectFileName find " t_") == -1 && (_objectFileName find " b_") == -1) then {
          _intersectionASL = _x select 0;
          breakOut "surfaceLoop";
        };
      }
      forEach _surfaces;

      if (count _intersectionASL != 0) then {
        _player allowDamage false;
        _player setPosASL _intersectionASL;
      };

      if (_player getVariable["AR_Detach_Rope", false]) then {
        // Player detached from rope. Don't prevent damage 
        // if we didn't find a position on the ground
        if (count _intersectionASL == 0) then {
          _player allowDamage true;
        };
      };

      // Allow damage if you get out of a heli with no engine on
      if (!isEngineOn _heli) then {
        _player allowDamage true;
      };

    };

    deleteVehicle _anchor;
    _rappelDevice ropeDetach _bottomRope;

    _player setVariable["AR_Is_Rappelling", nil, true];
    _player setVariable["AR_Rappelling_Vehicle", nil, true];
    _player setVariable["AR_Detach_Rope", nil];

    if (_ropeKeyDownHandler != -1) then {
      (findDisplay 46) displayRemoveEventHandler["KeyDown", _ropeKeyDownHandler];
    };

    if (_ropeKeyUpHandler != -1) then {
      (findDisplay 46) displayRemoveEventHandler["KeyUp", _ropeKeyUpHandler];
    };

    sleep 2;

    _player allowDamage true;

    sleep 10;
    deleteVehicle _rappelDevice;
    ropeDestroy _topRope;
    ropeDestroy _bottomRope;

  } else {
    [_this, "AR_Client_Rappel_From_Heli", _player] call AR_RemoteExec;
  };
};

APR_Request_Pickup_Rope_Action = {
  params["_player", "_vehicle"];
  if ([_player, _vehicle] call AR_Rappel_From_Heli_Action_Check) then {
    [_player, _vehicle] call APR_Pickup_Rope;
  };
};

APR_Pickup_Rope_Add_Player_Actions = {
  params["_player"];

  _player addAction["Request Pickup Rope", {
    [player, cursorTarget] call APR_Request_Pickup_Rope_Action;
  }, nil, 0, false, true, "", "[player, cursorTarget] call AR_Rappel_From_Heli_Action_Check"];

  _player addEventHandler["Respawn", {
    player setVariable["APR_Pickup_Rope_Player_Actions_Loaded", false];
  }];
};

if (!isDedicated) then {
  [] spawn {
    while {
      true
    }
    do {
      if (!isNull player && isPlayer player) then {
        if !(player getVariable["APR_Pickup_Rope_Player_Actions_Loaded", false]) then {
          [player] call APR_Pickup_Rope_Add_Player_Actions;
          player setVariable["APR_Pickup_Rope_Player_Actions_Loaded", true];
        };
      };
      sleep 5;
    };
  };
};
