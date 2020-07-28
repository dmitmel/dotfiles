// ac2pic: NOOOOO YOU CAN'T JUST PUT EVERYTHING IN POSTSTART/MAIN
// dmitmel: haha text editor go brrrr

export {};

ig.input.bind(ig.KEY.J, 'aim');
ig.input.bind(ig.KEY.K, 'dash');

function findRootGuiElement(clazz) {
  return ig.gui.guiHooks.find(({ gui }) => gui instanceof clazz).gui;
}

const quickMenu = findRootGuiElement(sc.QuickMenu);

const myAddon = {
  name: 'btw I use Arch addon',

  onPostUpdate() {
    if (ig.loading || sc.model.isPlayerControlBlocked()) return;

    if (ig.input.pressed('btw-i-use-arch.open-map-menu')) {
      if (
        sc.model.isGame() &&
        sc.model.isMenu() &&
        sc.menu.currentMenu === sc.MENU_SUBMENU.MAP &&
        // check if the help screen or a dialog isn't opened, otherwise it will
        // block the screen after switching back to the game
        ig.interact.entries.last() === sc.menu.buttonInteract
      ) {
        closeMapMenu();
        sc.BUTTON_SOUND.back.play();
      } else if (
        sc.model.isGame() &&
        sc.model.isRunning() &&
        // check if the quick menu has been unlocked yet, the map menu becomes
        // available at the same moment
        sc.model.player.getCore(sc.PLAYER_CORE.QUICK_MENU)
      ) {
        let openedMapMenu = openMapMenu();
        sc.BUTTON_SOUND[openedMapMenu ? 'submit' : 'denied'].play();
      }
    }
  },
};

ig.ENTITY.Crosshair.inject({
  // Normally the `this._getThrowerPos` method is used to calculate where the
  // balls are thrown _from_ in almost screen coordinates, but we can repurpose
  // it to calculate where the balls should be thrown _at_ to hit an entity.
  _getThrowPosForEntity(outVec2, entity) {
    let realThrower = this.thrower;
    try {
      this.thrower = entity;
      return this._getThrowerPos(outVec2);
    } finally {
      this.thrower = realThrower;
    }
  },
});

// these two constants will come in handy later, see `focusNextEntity`
const ENTITY_FOCUS_DIRECTION = {
  FARTHER: 1,
  CLOSER: -1,
};

// buffer vectors for calculations
let vec2a = Vec2.create();
let vec2b = Vec2.create();

sc.PlayerCrossHairController.inject({
  focusedEntity: null,
  prevMousePos: Vec2.createC(-1, -1),

  updatePos(...args) {
    // gamepad mode is unsupported because I don't have one to test this code on
    if (this.gamepadMode) {
      this.parent(...args);
      return;
    }

    let [crosshair] = args;

    // focus the next available entity if this combatant is e.g. dead
    if (
      this.focusedEntity != null &&
      !this.shouldEntityBeFocused(this.focusedEntity)
    ) {
      this.focusNextEntity(crosshair, ENTITY_FOCUS_DIRECTION.CLOSER);
    }

    let mouseX = sc.control.getMouseX();
    let mouseY = sc.control.getMouseY();
    if (
      this.focusedEntity != null &&
      // unfocus if the mouse has been moved
      (this.prevMousePos.x !== mouseX || this.prevMousePos.y !== mouseY)
    ) {
      this.focusedEntity = null;
    }
    Vec2.assignC(this.prevMousePos, mouseX, mouseY);

    // handle controls
    let pressedFocusCloser = ig.input.pressed('circle-left');
    let pressedFocusFarther = ig.input.pressed('circle-right');
    if (pressedFocusCloser) {
      this.focusNextEntity(crosshair, ENTITY_FOCUS_DIRECTION.CLOSER);
    }
    if (pressedFocusFarther) {
      this.focusNextEntity(crosshair, ENTITY_FOCUS_DIRECTION.FARTHER);
    }
    if (
      (pressedFocusCloser || pressedFocusFarther) &&
      this.focusedEntity == null
    ) {
      sc.BUTTON_SOUND.denied.play();
    }

    if (this.focusedEntity != null) {
      this.calculateCrosshairPos(crosshair);
    } else {
      this.parent(...args);
    }
  },

  focusNextEntity(crosshair, direction) {
    let throwerPos = crosshair._getThrowerPos(vec2a);

    function getSqrDistToEntity(entity) {
      let entityPos = crosshair._getThrowPosForEntity(vec2b, entity);
      return Vec2.squareDistance(throwerPos, entityPos);
    }

    let prevFocusedEntity = this.focusedEntity;
    let prevFocusedSqrDist =
      prevFocusedEntity != null ? getSqrDistToEntity(prevFocusedEntity) : null;
    this.focusedEntity = null;

    let closestNextEntitySqrDist = null;
    for (let entity of this.findFocusingCandidateEntities()) {
      if (entity === prevFocusedEntity) continue;

      let sqrDist = getSqrDistToEntity(entity);
      if (
        // multiplication by `dirFactor` effectively inverts the comparison
        // operator when it is negative, otherwise logically the expression
        // stays the same
        (prevFocusedSqrDist == null ||
          sqrDist * direction > prevFocusedSqrDist * direction) &&
        (closestNextEntitySqrDist == null ||
          sqrDist * direction < closestNextEntitySqrDist * direction)
      ) {
        closestNextEntitySqrDist = sqrDist;

        this.focusedEntity = entity;
      }
    }
  },

  shouldEntityBeFocused(combatant) {
    return (
      !combatant.isDefeated() &&
      // `sc.ENEMY_AGGRESSION.TEMP_THREAT` exists, but to be honest I have no
      // idea what it is supposed to do
      combatant.aggression === sc.ENEMY_AGGRESSION.THREAT
    );
  },

  findFocusingCandidateEntities() {
    let allCombatants = sc.combat.activeCombatants[sc.COMBATANT_PARTY.ENEMY];
    let candidates = allCombatants.filter((enemy) =>
      this.shouldEntityBeFocused(enemy),
    );

    if (candidates.length === 0) {
      candidates = ig.game.shownEntities.filter(
        (entity) =>
          entity != null &&
          !entity._killed &&
          entity instanceof ig.ENTITY.Enemy &&
          ig.CollTools.isInScreen(entity.coll) &&
          this.shouldEntityBeFocused(entity),
      );
    }

    return candidates;
  },

  calculateCrosshairPos(crosshair) {
    let { thrower } = crosshair;
    let throwerPos = crosshair._getThrowerPos(vec2a);
    let entityPos = crosshair._getThrowPosForEntity(vec2b, this.focusedEntity);
    let entityVel = this.focusedEntity.coll.vel;

    let ballInfo = sc.PlayerConfig.getElementBall(
      thrower,
      thrower.model.currentElementMode,
      // NOTE: This causes glitches when the ball speed affects the crosshair
      // position too much, in which case it begins jumping back and forth
      // because the charged status is reset due to the movement. I hope this
      // isn't to much of a problem.
      crosshair.isThrowCharged(),
    );
    let ballSpeed = ballInfo.data.speed;

    let crosshairPos = crosshair.coll.pos;
    Vec2.assign(crosshairPos, entityPos);
    // perform entity movement prediction repeatedly to increase the precision
    for (let i = 0; i < 3; i++) {
      let t = Vec2.distance(throwerPos, crosshairPos) / ballSpeed;
      crosshairPos.x = entityPos.x + Math.round(entityVel.x) * t;
      crosshairPos.y = entityPos.y + Math.round(entityVel.y) * t;
    }
  },
});

const PLAYER_LOCATION_IN_ROOM_ICON = {
  x: 280,
  y: 436,
  w: 10,
  h: 9,
};

sc.MapCurrentRoomWrapper.inject({
  updateDrawables(renderer) {
    this.parent(renderer);

    let player = ig.game.playerEntity;
    let x = player.coll.pos.x * (this.hook.size.x / ig.game.size.x);
    let y = player.coll.pos.y * (this.hook.size.y / ig.game.size.y);

    let sprite = PLAYER_LOCATION_IN_ROOM_ICON;
    renderer.addGfx(
      this.gfx,
      Math.round(x - sprite.w / 2),
      Math.round(y - sprite.h / 2),
      sprite.x,
      sprite.y,
      sprite.w,
      sprite.h,
    );
  },
});

function openMapMenu() {
  // Check for the common conditions upfront, because opening and then
  // immediately closing the quick menu causes the element indicator in the top
  // left corner to jump, which is, of course, undesirable. Other conditions may
  // be present implicitly or added explicitely in the future, but these two are
  // the obvious ones I could find.
  if (!sc.model.isSaveAllowed() || sc.model.isTeleportBlocked()) return false;

  // User's actions required in order to open the map need to be carefully
  // emulated here instead of directly calling methods of `sc.model` and
  // `sc.menu` because of the model notifications sent during the intended user
  // interaction path (which trigger changes to the UI all over the codebase)
  // and potential (although unlikely) changes to the internals of the methods
  // I'm using here. Also, I chose to use the quick menu instead of the main one
  // because the main one is unlocked at the end of the rhombus dungeon which is
  // a bit later than the quick one and the map menu in particular both become
  // available.
  let enteredQuickMenu = sc.model.enterQuickMenu();
  if (!enteredQuickMenu) return false;
  // I wonder why this variable isn't set internally by `enteredQuickMenu`, but
  // I have to do this here because not doing that creates a very annoying bug
  // when the quick menu access method is set to "hold": the quick menu becomes
  // impossible to close by pressing shift and to close it you have to open and
  // close the map menu again manually.
  sc.quickmodel.activeState = true;

  let quickRingMenu = quickMenu.ringmenu;
  let mapButton = quickRingMenu.map;
  if (!mapButton.active) {
    // some additional conditions may be present as noted above, so in the case
    // the button intended to be pressed by user is inactive we bail out safely
    sc.quickmodel.activeState = false;
    sc.model.enterRunning();
    return false;
  }

  // And finally, press the "map" button!
  quickRingMenu.buttongroup._invokePressCallbacks(
    mapButton,
    /* fromMouse */ false,
  );
  return true;
}

function closeMapMenu() {
  // Let's exit the world map just in case, for the same reason as I emulate
  // user interactions in the `openMapMenu` function.
  if (sc.menu.mapWorldmapActive) sc.menu.exitWorldMap();

  sc.model.enterPrevSubState();
}

{
  let globalInputAddonIdx = ig.game.addons.postUpdate.findIndex(
    (addon) => addon instanceof sc.GlobalInput,
  );
  console.assert(globalInputAddonIdx >= 0, 'inputPostUpdateIdx >= 0');
  ig.game.addons.postUpdate.splice(globalInputAddonIdx + 1, 0, myAddon);
}
