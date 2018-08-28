hs.loadSpoon("KSheet")

modal = hs.hotkey.modal.new({"cmd", "alt", "ctrl"}, "c")

function modal:entered() spoon.KSheet:show() end
function modal:exited()  spoon.KSheet:hide() end

modal:bind('', 'escape', function() modal:exit() end)
