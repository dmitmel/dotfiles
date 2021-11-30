class MyPlugin {
  constructor(plugin) {
    this.plugin = plugin;
    this.counter = 0;
    plugin.registerFunction('_dotfiles_rpc_counter', this.rpc_counter.bind(this), { sync: true });
  }

  rpc_counter() {
    this.counter += 1;
    return this.counter;
  }
}

module.exports = MyPlugin;
