// Vim keys for Obsidian's core File explorer, like Neo-tree in Neovim:
//   j/k  down/up            h  collapse / go to parent
//   l    open file, or expand folder / go to first child
//   gg/G first/last item    r  rename      /  filter tree (same as Cmd+F)
//   a    new note           A  new folder
//        (inside the focused folder, or beside the focused file, as Neo-tree)
//
// Own plugin instead of a community one, to keep third-party code out of
// the vault. Uses undocumented internals checked against Obsidian 1.15.0:
// view.tree.{scope, focusedItem, root, changeFocusedItem, onKeyArrow*,
// onKeyOpen, handleRenameFocusedItem}, view.showSearch() and
// view.createAbstractFile(). If an Obsidian
// update breaks a key, check those names in the app bundle first.
//
// Keys are registered on the tree's own Scope, so they only fire while the
// explorer has focus. Typing in the filter box or a rename field is left
// alone. Enabled by modify_community-plugins.json.

const { Plugin, TFolder } = require("obsidian");

const GG_TIMEOUT_MS = 500;

function isEditable(target) {
  return (
    target instanceof HTMLElement &&
    (target.isContentEditable || /^(INPUT|TEXTAREA)$/.test(target.tagName))
  );
}

module.exports = class ExplorerVimKeys extends Plugin {
  onload() {
    this.bound = new Map(); // scope -> handlers
    this.app.workspace.onLayoutReady(() => this.attach());
    this.registerEvent(this.app.workspace.on("layout-change", () => this.attach()));
  }

  onunload() {
    for (const [scope, handlers] of this.bound) {
      for (const h of handlers) scope.unregister(h);
    }
    this.bound.clear();
  }

  attach() {
    for (const leaf of this.app.workspace.getLeavesOfType("file-explorer")) {
      const view = leaf.view;
      const tree = view && view.tree;
      if (!tree || !tree.scope || this.bound.has(tree.scope)) continue;
      this.bound.set(tree.scope, this.register(view, tree));
    }
  }

  register(view, tree) {
    let lastG = 0;
    const jumpTo = (direction) => {
      // From the root, the tree's own stepping lands on the first or last
      // visible item, honouring collapsed folders and the filter.
      const old = tree.focusedItem;
      if (old && old !== tree.root && old.selfEl) old.selfEl.removeClass("has-focus");
      tree.focusedItem = tree.root;
      tree.changeFocusedItem(direction);
    };
    // Neo-tree semantics: on a folder, create inside it; on a file, beside it.
    const targetFolder = () => {
      const item = tree.focusedItem;
      const file = item && item !== tree.root ? item.file : null;
      if (file instanceof TFolder) return file;
      return (file && file.parent) || this.app.vault.getRoot();
    };
    const keys = [
      [[], "j", (e) => tree.onKeyArrowDown(e)],
      [[], "k", (e) => tree.onKeyArrowUp(e)],
      [[], "h", (e) => tree.onKeyArrowLeft(e)],
      [[], "l", (e) => {
        const item = tree.focusedItem;
        if (item && item.file && !(item.file instanceof TFolder)) tree.onKeyOpen(e);
        else tree.onKeyArrowRight(e);
      }],
      [[], "g", () => {
        const now = Date.now();
        if (now - lastG < GG_TIMEOUT_MS) {
          jumpTo("forwards");
          lastG = 0;
        } else {
          lastG = now;
        }
      }],
      [["Shift"], "G", () => jumpTo("backwards")],
      [[], "r", (e) => tree.handleRenameFocusedItem && tree.handleRenameFocusedItem(e)],
      [[], "/", () => view.showSearch(false)],
      // New note opens with its title selected for naming; a new folder
      // starts an inline rename in the tree, as Obsidian's own buttons do.
      [[], "a", () => view.createAbstractFile("file", targetFolder())],
      [["Shift"], "A", () => view.createAbstractFile("folder", targetFolder())],
    ];
    return keys.map(([mods, key, fn]) =>
      tree.scope.register(mods, key, (e) => {
        if (isEditable(e.target)) return true; // let the key type normally
        fn(e);
        return false; // handled: preventDefault
      })
    );
  }
};
