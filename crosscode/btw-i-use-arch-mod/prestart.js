sc.OPTIONS_DEFINITION['keys-btw-i-use-arch.open-map-menu'] = {
  type: 'CONTROLS',
  cat: sc.OPTION_CATEGORY.CONTROLS,
  init: { key1: ig.KEY.M },
  hasDivider: true,
  header: 'btw-i-use-arch',
};

ig.KEY.MOUSE_LEFT = ig.KEY.MOUSE1;
ig.KEY.MOUSE_RIGHT = ig.KEY.MOUSE2;
ig.KEY.MOUSE_MIDDLE = -6;
ig.KEY.MOUSE_BACK = -7;
ig.KEY.MOUSE_FORWARD = -8;

// As for the copied implementations of ig.Input#keydown and ig.Input#keyup:
// there is probably a way to avoid copying, most notably by abusing the logic
// of the keyCode check. See, in both methods it is basically the same, just
// with differing event names, but the logic is as follows: if the event is a
// keyboard event, get the `keyCode` property, otherwise check if
// `event.button` is 2, then assume the key is `ig.KEY.MOUSE2`, otherwise
// `ig.KEY.MOUSE1`. This means that I could replace the value of the `MOUSE1`
// constant to the keyCode determined with my custom logic, and so the fallback
// path will read my value, but ultimately I didn't do that because I figured
// there might be other parts of these functions which can use some
// refactoring.
ig.Input.inject({
  keydown(event) {
    if (
      ig.system.crashed ||
      this.isInIframeAndUnfocused() ||
      (this.ignoreKeyboard && event.type !== 'mousedown')
    ) {
      return;
    }

    if (ig.system.hasFocusLost()) {
      if (event.type === 'mousedown') {
        ig.system.regainFocus();
      }
      return;
    }

    if (event.type === 'mousedown') {
      this.mouseGuiActive = true;
    }
    this.currentDevice = ig.INPUT_DEVICES.KEYBOARD_AND_MOUSE;

    if (event.target.type === 'text') {
      return;
    }

    let keyCode = this.getKeyCodeFromEvent(event);

    if (
      // It's quite interesting that the game kinda supports touch events, but
      // they are never actually used in practice.
      event.type === 'touchstart' ||
      event.type === 'mousedown'
    ) {
      this.mousemove(event);
    }

    let action = this.bindings[keyCode];
    if (action != null) {
      this.actions[action] = true;
      // Not sure what are locks supposed to do. Oh wait, I figured it out:
      // this is so that if a button is detected to be pressed in a frame, but
      // if an un-press event is caught during the processing of the frame, the
      // button... Hmmm, still not sure. Entirety of the game logic blocks the
      // main thread, so it's impossible to catch two events during processing
      // of the frame.
      if (!this.locks[action]) {
        this.presses[action] = true;
        this.locks[action] = true;
      }
      event.stopPropagation();
      event.preventDefault();
    }
  },

  keyup(event) {
    if (
      ig.system.crashed ||
      this.isInIframeAndUnfocused() ||
      (this.ignoreKeyboard && event.type !== 'mouseup') ||
      event.target.type === 'text' ||
      (ig.system.hasFocusLost() && event.type === 'mouseup')
    ) {
      return;
    }

    this.currentDevice = ig.INPUT_DEVICES.KEYBOARD_AND_MOUSE;

    let keyCode = this.getKeyCodeFromEvent(event);

    let action = this.bindings[keyCode];
    if (action != null) {
      this.keyups[action] = true;
      this.delayedKeyup.push(action);
      event.stopPropagation();
      event.preventDefault();
    }
  },

  getKeyCodeFromEvent(event) {
    switch (event.type) {
      case 'keyup':
      case 'keydown':
        return event.keyCode;

      case 'mouseup':
      case 'mousedown':
        switch (event.button) {
          case 0:
            return ig.KEY.MOUSE_LEFT;
          case 1:
            return ig.KEY.MOUSE_MIDDLE;
          case 2:
            return ig.KEY.MOUSE_RIGHT;
          case 3:
            return ig.KEY.MOUSE_BACK;
          case 4:
            return ig.KEY.MOUSE_FORWARD;
        }
    }

    // idk, fall back to the left mouse button. That's kind of what the default
    // implementation does though.
    return ig.KEY.MOUSE_LEFT;
  },
});

// Finally, some nice injection places.
sc.KeyBinderGui.inject({
  show(...args) {
    this.parent(...args);
    window.addEventListener('mousedown', this.bindedKeyCheck, false);
  },

  hide(...args) {
    this.parent(...args);
    window.removeEventListener('mousedown', this.bindedKeyCheck);
  },

  onKeyCheck(event) {
    event.preventDefault();

    let keyCode = ig.input.getKeyCodeFromEvent(event);
    if (ig.interact.isBlocked() || this._isBlackedListed(keyCode)) return;

    // This call was added by me. Just in case. Because the `stopPropagation`
    // call in `ig.Input` saved me from re-binds of left/right mouse buttons to
    // whatever else other than interactions with menus.
    event.stopPropagation();

    if (this.finishCallback != null) {
      this.finishCallback(keyCode, this.isAlternative, false);
    }
    this.hide();
  },
});
