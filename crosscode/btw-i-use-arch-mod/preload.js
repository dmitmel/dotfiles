// I know that this is legacy feature provided by CCLoader way back when mods
// weren't executed inside the game iframe's context, but it is useful
// nevertheless because console in Chrome's devtools automatically selects
// window.top as the execution context by default, so writing `cc.` is faster
// than `modloader.frame.contentWindow`
window.top.cc = window;
