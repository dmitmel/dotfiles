ig.module('game.feature.masochist.keyboard-controls')
  .requires('game.main')
  .defines(() => {
    sc.CrossCode.inject({
      init() {
        this.parent();
        ig.input.bind(ig.KEY.J, 'aim');
        ig.input.bind(ig.KEY.K, 'dash');
      },
    });
  });
