// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 Victor Eduardo <victoreduardm@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


/**
 * A widget that can display a list of items organized in categories.
 *
 * The sidebar widget consists of a collection of items, some of which are also categories (and
 * thus can contain more items). All the items displayed in the sidebar are children of the widget's
 * root category. The API is meant to be used as follows:
 *
 * 1. Create the items you want to display in the sidebar, setting the appropriate values for their
 * properties. The desired hierarchy is achieved by creating categories and adding items to them.
 * These will be displayed as descendants in the widget's tree structure. The categories that are
 * not nested inside any other category are considered to be at root level, and should be added to
 * the widget's root category.<<BR>>
 *
 * ''Example''<<BR>>
 * The final tree will have the following structure:
 * {{{
 * Libraries
 *   Music
 * Stores
 *   My Store
 *      Music
 *      Podcasts
 * Devices
 *   Player 1
 *   Player 2
 * }}}
 *
 * {{{
 * var library_category = new Granite.Widgets.Sidebar.Category ("Libraries");
 * var store_category = new Granite.Widgets.Sidebar.Category ("Stores");
 * var device_category = new Granite.Widgets.Sidebar.Category ("Devices");
 *
 * var music_item = new Granite.Widgets.Sidebar.Item ("Music");
 *
 * // "Libraries" will be the parent category of "Music"
 * library_category.add_item (music_item);
 *
 * var my_store_category = new Granite.Widgets.Sidebar.Category ("My Store");
 * store_category.add_item (my_store_category);
 *
 * var my_store_podcast_item = new Granite.Widgets.Sidebar.Item ("Podcasts");
 * var my_store_music_item = new Granite.Widgets.Sidebar.Item ("Music");
 *
 * my_store_category.add_item (my_store_music_item);
 * my_store_category.add_item (my_store_podcast_item);
 *
 * var player1_item = new Granite.Widgets.Sidebar.Item ("Player 1");
 * var player2_item = new Granite.Widgets.Sidebar.Item ("Player 2");
 *
 * device_category.add_item (player1_item);
 * device_category.add_item (player2_item);
 * }}}
 *
 * 2. Create a sidebar widget.<<BR>>
 * {{{
 * var sidebar = new Granite.Widgets.Sidebar ();
 * }}}
 *
 * 3. Add root-level categories and/or items to the {@link Granite.Widgets.Sidebar.root} category.
 * This category only serves as a container, and all its properties are ignored by the widget.
 *
 * {{{
 * // This will add the main categories (including their children) to the sidebar. After
 * // having being added to be widget, any other item added to any of these categories
 * // (or any other child category in a deeper level) will be automatically added too.
 * // There's no need to deal with the sidebar widget directly.
 *
 * var root = sidebar.root;
 *
 * root.add_item (library_category);
 * root.add_item (store_category);
 * root.add_item (device_category);
 * }}}
 *
 * The steps mentioned above are enough for initializing the sidebar. Future changes to the items'
 * properties are ''automatically'' reflected by the widget.
 *
 * Final steps would involve connecting handlers to the sidebar events, being
 * {@link Granite.Widgets.Sidebar.item_selected} the most important, as it indicates that
 * the selection was modified.
 *
 * It is strongly recommended to pack the sidebar into the GUI using the
 * {@link Granite.Widgets.SidebarPaned} widget. It has aesthetic advantages and offers a wider
 * re-size handle than usual Paned widgets do. This is usually done as follows:
 * {{{
 * var sidebar_paned = new Granite.Widgets.SidebarPaned ();
 * sidebar_paned.pack1 (sidebar, true, false);
 * sidebar_paned.pack2 (content_area, true, false);
 * }}}
 *
 * @since 0.2
 * @see Granite.Widgets.SidebarPaned
 */
public class Granite.Widgets.Sidebar : Gtk.ScrolledWindow {

    /**
     * = WORKING INTERNALS =
     *
     * In order to offer a transparent Item-based API, and avoid the need of providing methods
     * to deal with items directly on the Sidebar widget, it was decided to follow a monitor-like
     * implementation, where the sidebar permanently monitors its root category and any other
     * child item added to it. The task of monitoring the properties of the items has been
     * divided between different objects, as shown below:
     *
     * Monitored by: Object::method that receives the signals indicating the property change.
     * Applied by: Object::method that actually updates (directly or indirectly, as in the case of
     *             the tree model) the tree to reflect the property changes.
     *
     * ---------------------------------------------------------------------------------------------
     *   PROPERTY        |  MONITORED BY                     |  APPLIED BY
     * ---------------------------------------------------------------------------------------------
     * + Item            |                                   |
     *   - parent        | Not monitored                     | N/A
     *   - name          | Sidebar::on_item_property_changed | Sidebar::name_cell_data_func
     *   - editable      | Sidebar::on_item_property_changed | Queried when needed (See on_text_renderer_edit)
     *   - visible       | Sidebar::on_item_property_changed | FilteredDataModel::filter_visible_func
     *   - icon          | Sidebar::on_item_property_changed | Sidebar::icon_cell_data_func
     *   - activatable   | Same as @icon                     | Same as @icon
     * + Category        |                                   |
     *   - no_caption    | Sidebar::on_item_property_changed | Sidebar::name_cell_data_func
     *   - collapsible   | Sidebar::on_item_property_changed | Sidebar::update_tree_expansion
     *                   |                                   | Sidebar::expander_cell_data_func
     *   - expanded      | Same as @collapsible              | Same as @collapsible
     * ---------------------------------------------------------------------------------------------
     * * Only automatic properties are monitored. Category's add/removals are handled by
     *   Sidebar::add_item and Sidebar::remove_item
     *
     * Other features:
     * - Sorting: this happens on the tree-model-level. See FilteredDataModel and Sidebar::SortFunc.
     */



    /**
     * A sidebar entry. Any change made to any of its properties will be ''automatically'' reflected
     * by the {@link Granite.Widgets.Sidebar} widget.
     *
     * @since 0.2
     */
    public class Item : Object {

        /**
         * Emitted every time a property changes.
         *
         * @param self Self.
         * @param prop_name Property name.
         * @since 0.2
         */
        public virtual signal void changed (Item self, string prop_name) {
#if TRACE_SIDEBAR
            debug ("Item::changed[%s] [%s]", prop_name, name);
#endif
        }

        /**
         * Emitted when the user has finished editing the item's name. By default, if the name doesn't consist
         * of white space, it is automatically asigned to the {@link Granite.Widgets.Sidebar.name} property.
         *
         * @since 0.2
         */
        public virtual signal void edited (string new_name) {
#if TRACE_SIDEBAR
            debug ("Item::edited [%s]\tnew_name = %s", name, new_name);
#endif
            if (new_name.strip () != "")
                this.name = new_name;
        }

        /**
         * The {@link Granite.Widgets.Sidebar.Item.activatable} icon was activated.
         *
         * @param time Time when the event took place.
         * @see Granite.Widgets.Sidebar.Item.activatable
         * @since 0.2
         */
        public virtual signal void action_activated (uint32 time) {
#if TRACE_SIDEBAR
            debug ("Item::action_activated [%s]", name);
#endif
        }

        /**
         * Emitted when the item is double-clicked or when it is selected and one of the keys:
         * Space, Shift+Space, Return or Enter is pressed. This signal is //not emitted// for
         * editable items.
         *
         * @since 0.2
         */
        public virtual signal void activated () {
#if TRACE_SIDEBAR
            debug ("Item::activated [%s]", name);
#endif
        }

        /**
         * Parent {@link Granite.Widgets.Sidebar.Category} of the item.
         *
         * @since 0.2
         */
        public Category parent { get; internal set; }

        /**
         * The item's name. Primary and most important information.
         *
         * @since 0.2
         */
        public string name { get; set; default = ""; }

        /**
         * A counter shown in a bubble right next to the item's name. It can be used for displaying
         * the number of unread messages in the "Inbox" item, for instance. ''Still not implemented''.
         *
         * @since 0.2
         */
        public uint count { get; set; default = 0; }

        /**
         * Whether the item's name can be edited from within the sidebar.
         *
         * @since 0.2
         */
        public virtual bool editable { get; set; default = false; }

        /**
         * Whether the item will appear in the sidebar's tree or not.
         *
         * @since 0.2
         */
        public virtual bool visible { get; set; default = true; }

        /**
         * Whether the item can be selected or not.
         *
         * There are a couple reasons that could make the item not-selectable:<<BR>>
         * * The item is not visible<<BR>>
         * * The item's parent category is collapsed<<BR>>
         *
         * @see Granite.Widgets.Sidebar.Item.visible
         * @since 0.2
         */
        public virtual bool selectable {
            get {
                bool rv = false;

                // we won't select items hidden behind a collapsed category
                if (parent != null && !(parent.collapsible && !parent.expanded))
                    rv = visible;

                return rv;
            }
        }

        /**
         * Primary icon. This property should be used to give the user an idea of what the
         * item represents (i.e. content type.)
         *
         * @since 0.2
         */
        public Icon icon { get; set; }

        /**
         * An activatable icon that works like a button. It can be used for e.g. showing an
         * "eject" icon on a device's sidebar item.
         *
         * @see Granite.Widgets.Sidebar.Item.action_activated
         * @since 0.2
         */
        public Icon activatable { get; set; }


        /**
         * Creates a new {@link Granite.Widgets.Sidebar.Item}.
         *
         * @param name Name of the item.
         * @return (transfer full) A new {@link Granite.Widgets.Sidebar.Item}.
         * @since 0.2
         */
        public Item (string name = "") {
            this.name = name;
            this.notify.connect (on_property_changed);
        }

        /**
         * Invoked when the item is secondary-clicked or when the usual menu keys are pressed.
         *
         * @return A {@link Gtk.Menu} or //null// if nothing should be displayed.
         * @since 0.2
         */
        public virtual Gtk.Menu? get_context_menu () {
            return null;
        }

        private void on_property_changed (ParamSpec prop) {
            changed (this, prop.name);
        }
    }



    /**
     * An item that can contain more items. It supports all the properties inherited from
     * {@link Granite.Widgets.Sidebar.Item}, //except for// {@link Granite.Widgets.Sidebar.Item.activatable},
     * {@link Granite.Widgets.Sidebar.Item.count}, and {@link Granite.Widgets.Sidebar.Item.icon}.
     * These are simply ignored by the {@link Granite.Widgets.Sidebar} widget.
     *
     * Categories are //__not editable__// by default, and thus not selectable (although they are
     * clickable.) They can be made selectable by setting the {@link Granite.Widgets.Sidebar.Item.editable}
     * property to //true//.
     *
     * //Categories containing zero visible items are not displayed//.
     *
     * @since 0.2
     */
    public class Category : Item {

        /**
         * Emitted when an item is added to the category.
         *
         * @param item Item added.
         * @see Granite.Widgets.Sidebar.Category.add_item
         * @since 0.2
         */
        public signal void child_added (Item item);

        /**
         * Emitted when an item is removed from the category.
         *
         * @param item Item removed.
         * @see Granite.Widgets.Sidebar.Category.remove_item
         * @since 0.2
         */
        public signal void child_removed (Item item);

        /**
         * Sidebar category items are usually displayed in bold fonts; this allows for disabling
         * that. It is useful when e.g. showing a file tree, where Category items represent a
         * directory. In such case, having bolded directory names among non-bolded file names may
         * look odd.
         *
         * As this property can create visual inconsistency between applications, it is recommended
         * to avoid enabling it, except for those situations where it actually makes the sidebar
         * look better.
         *
         * @since 0.2
         */
        public bool no_caption { get; set; default = false; }

        /**
         * Whether the category is collapsible or not. When set to //false//, the category
         * is always expanded and the expander is not shown.
         *
         * @see Granite.Widgets.Sidebar.Category.expanded
         * @since 0.2
         */
        public bool collapsible { get; set; default = true; }

        /**
         * Whether the category is expanded or not. This property has no effect when
         * {@link Granite.Widgets.Sidebar.Category.collapsible} is //false//.
         *
         * @see Granite.Widgets.Sidebar.Category.collapsible
         * @since 0.2
         */
        public bool expanded { get; set; default = false; }

        /**
         * {@inheritDoc}
         *
         * //Categories containing zero visible children are not visible.//
         *
         * @see Granite.Widgets.Sidebar.Item.visible
         * @since 0.2
         */
        public override bool visible {
            get {
                uint n_visible = 0;
                foreach (var item in get_children ()) {
                    if (item.visible)
                        n_visible ++;
                }
                return base.visible && n_visible > 0;
            }
            set {
                base.visible = value;
            }
        }

        /**
         * {@inheritDoc}
         *
         * //Non-editable categories are not selectable.//
         * See {@link Granite.Widgets.Sidebar.Item.selectable} for further details.
         *
         * @see Granite.Widgets.Sidebar.Item.selectable
         * @see Granite.Widgets.Sidebar.Item.editable
         * @see Granite.Widgets.Sidebar.Category.expanded
         * @see Granite.Widgets.Sidebar.Category.collapsible
         * @since 0.2
         */
        public override bool selectable {
            get { return base.selectable && editable; }
        }

        /**
         * Number of child items contained by the category.
         *
         * @since 0.2
         * @see Granite.Widgets.Sidebar.Category.get_children
         */
        public uint n_children {
            get { return children.size; }
        }

        private Gee.Set<Item> children = new Gee.HashSet<Item> ();

        /**
         * Creates a new {@link Granite.Widgets.Sidebar.Category}
         *
         * @param name Title of the category.
         * @return (transfer full) A new {@link Granite.Widgets.Sidebar.Category}.
         * @since 0.2
         */
        public Category (string name = "") {
            base (name);
            editable = false;
        }

        /**
         * Gets all the items which are part of the category.
         *
         * @return (transfer full) Children.
         * @see Granite.Widgets.Sidebar.Category.n_children
         * @since 0.2
         */
        public Gee.Set<Item> get_children () {
            var chilren_set = new Gee.HashSet<Item> ();
            var to_remove = new Gee.LinkedList<Item> ();

            foreach (var item in children) {
                if (item.parent == this)
                    chilren_set.add (item);
                else
                    to_remove.add (item);
            }

            foreach (var item in to_remove) {
                // Silently remove items that don't belong here
                children.remove (item);
            }

            return chilren_set;
        }

        /**
         * Adds an item to the category. Since Categories are also items, it can also add sub-categories.
         *
         * {@link Granite.Widgets.Sidebar.Category.child_added} is fired after the item is added.
         *
         * While adding the item, //the category sets itself as the item's parent//. Please note
         * that items are required to have their //parent// property set to //null// before being added,
         * so make sure you remove the item from its previous category before adding it to the new category.
         * This can be done as follows:
         * {{{
         * if (item.parent != null)
         *     item.parent.remove (item); // this will set item's parent to null
         * new_parent.add_item (item);
         * }}}
         *
         * @param item The item to add. Its parent __must__ be //null//.
         * @see Granite.Widgets.Sidebar.Category.child_added
         * @see Granite.Widgets.Sidebar.Category.remove_item
         * @since 0.2
         */
        public void add_item (Item item) requires (item.parent == null && !(item in children)) {
#if TRACE_SIDEBAR
            debug ("Category::add_item [%s]\titem = %s", name, item.name);
#endif

            lock (children) {
                item.parent = this;
                children.add (item);
            }

            child_added (item);
        }

        /**
         * Removes an item from the category.
         *
         * The {@link Granite.Widgets.Sidebar.Category.child_removed} signal is fired
         * //after removing the item//. Finally (i.e. after all the handlers have been invoked),
         * the item's {@link Granite.Widgets.Sidebar.Item.parent} property is set to //null//.
         * This has the advantage of letting signal handlers know the category from which the //item//
         * is being removed.
         *
         * @param item The item to remove. The category __must__ be its parent.
         * @see Granite.Widgets.Sidebar.Category.child_removed
         * @see Granite.Widgets.Sidebar.Category.clear
         * @since 0.2
         */
        public void remove_item (Item item) requires (item.parent == this && item in children) {
#if TRACE_SIDEBAR
            debug ("Category::remove_item [%s]\titem = %s", name, item.name);
#endif

            lock (children) {
                children.remove (item);
            }

            child_removed (item);
            item.parent = null;
        }

        /**
         * Removes all the items contained by the category. It works similarly to
         * {@link Granite.Widgets.Sidebar.Category.remove_item}.
         *
         * @see Granite.Widgets.Sidebar.Category.remove_item
         * @see Granite.Widgets.Sidebar.Category.child_removed
         * @since 0.2
         */
        public void clear () {
#if TRACE_SIDEBAR
            debug ("Category::clear [%s]", name);
#endif
            foreach (var item in get_children ())
                remove_item (item);
        }
    }



    private class CellRendererIcon : Gtk.CellRendererPixbuf {
        // These correspond to all the icons supported by Item objects
        public enum IconType {
            ICON,
            ACTIVATABLE
        }

        public IconType icon_type { get; construct; }

        private const Gtk.IconSize ICON_SIZE = Gtk.IconSize.MENU;

        public CellRendererIcon (IconType icon_type) {
            Object (icon_type: icon_type);
            set_alignment (0.5f, 0.5f);
            mode = Gtk.CellRendererMode.ACTIVATABLE;
            stock_size = ICON_SIZE;
            follow_state = true;
        }
    }



    /**
     * The model backing the Sidebar tree. It controls the visibility of the items.
     *
     * The FilteredDataModel controls the visibility of the items based on their "visible" property,
     * and also on their number of children, if they happen to be categories. It also offers an easy
     * interface for sorting, adding, removing and updating items, eliminating the need of repeatedly
     * dealing with the Gtk.TreeModel API directly.
     */
    private class FilteredDataModel : Gtk.TreeModelFilter {

        /**
         * An object that references a particular row in a model. This class is a wrapper built around
         * Gtk.TreeRowReference, and exists with the purpose of ensuring we never use invalid tree paths
         * or iters in the model, since most of these errors provoke failures due to GTK+ assertions
         * or even worse: unexpected behavior.
         */
        private class NodeWrapper {
            /**
             * The actual reference to the node. If is is null, it is treated as invalid.
             */
            private Gtk.TreeRowReference? row_reference;

            /**
             * A newly-created Gtk.TreeIter pointing to the node if it exists; null otherwise.
             */
            public Gtk.TreeIter? iter {
                owned get {
                    Gtk.TreeIter? rv = null;

                    if (valid) {
                        var _path = this.path;
                        if (_path != null) {
                            Gtk.TreeIter _iter;
                            if (row_reference.get_model ().get_iter (out _iter, _path))
                                rv = _iter;
                        }
                    }

                    return rv;
                }
            }

            /**
             * A newly-created Gtk.TreePath pointing to the node if it exists; null otherwise.
             */
            public Gtk.TreePath? path {
                owned get {
                    return valid ? row_reference.get_path () : null;
                }
            }

            /**
             * Whether the node is valid or not. When it is not valid, no valid references are
             * returned by the object to avoid errors (null is returned instead).
             */
            public bool valid {
                get { return row_reference != null && row_reference.valid (); }
            }

            public NodeWrapper (Gtk.TreeModel model, Gtk.TreeIter iter) {
                row_reference = new Gtk.TreeRowReference (model, model.get_path (iter));
            }
        }

        private enum Column {
            ITEM,
            N_COLUMNS;

            public Type type () {
                switch (this) {
                    case ITEM:
                        return typeof (Item);
                    default:
                        assert_not_reached (); // a Type must be returned for every valid column
                }
            }
        }

        /**
         * This hashmap stores items and their respective child node references. For that reason, the
         * references it contains should only be used on the child_tree model, or converted to filter
         * iters/paths using convert_child_*_to_*() before using them with the filter (i.e. this) model.
         */
        private Gee.HashMap<Item, NodeWrapper> items = new Gee.HashMap<Item, NodeWrapper> ();

        private Gtk.TreeStore child_tree;
        private Sidebar.SortFunc? sort_func;

        public FilteredDataModel () {
            var child_tree = new Gtk.TreeStore (Column.N_COLUMNS, Column.ITEM.type ());
            Object (child_model: child_tree, virtual_root: null);

            this.child_tree = child_tree;

            child_tree.set_default_sort_func (child_model_sort_func);
            child_tree.set_sort_column_id (Gtk.SortColumn.DEFAULT, Gtk.SortType.ASCENDING);

            set_visible_func (filter_visible_func);
        }

        public bool has_item (Item item) {
            return items.has_key (item);
        }

        public void update_item (Item item) requires (has_item (item)) {
#if TRACE_SIDEBAR
            debug ("FilteredDataModel::update_item [%s]", item.name);
#endif
            lock (child_tree) {
                // Emitting row_changed() for this item's row in the child model causes the filter
                // (i.e. this model) to re-evaluate whether a row is visible or not, calling
                // filter_visible_func for that row again, and that's exactly what we want.
                var node_reference = items.get (item);
                if (node_reference != null) {
                    var path = node_reference.path;
                    var iter = node_reference.iter;
                    if (path != null && iter != null)
                        child_tree.row_changed (path, iter);
                }
            }
        }

        public void add_item (Item item) requires (!has_item (item)) {
#if TRACE_SIDEBAR
            debug ("FilteredDataModel::add_item [%s]", item.name);
#endif
            lock (child_tree) {
                // Try to find the parent. XXX: If the parent is not found, and item.parent != null,
                // we should call add_item(item.parent) in order to add it prior to adding the child
                // item. This will be mandatory if Item::parent ever becomes writable from client code.
                // It is currently not needed because of the way the sidebar operates: it adds categories
                // first, and then their children.
                Gtk.TreeIter? parent_child_iter = null, child_iter;
                if (item.parent != null)
                    parent_child_iter = get_item_child_iter (item.parent);

                child_tree.append (out child_iter, parent_child_iter);
                child_tree.set (child_iter, Column.ITEM, item, -1);

                items.set (item, new NodeWrapper (child_tree, child_iter));
            }
        }

        public void remove_item (Item item) requires (has_item (item)) {
#if TRACE_SIDEBAR
            debug ("FilteredDataModel::remove_item [%s]", item.name);
#endif
            lock (child_tree) {
                // get_item_child_iter() depends on @items.get(item) for retrieving the right reference,
                // so don't unset the item from @items yet! We first get the child iter and then
                // unset the value.
                var child_iter = get_item_child_iter (item);

                // Now we remove the item from the table, because that way get_item_iter() and
                // all the methods that depend on it won't return invalid iters or items when
                // called. This is important because child_tree.remove() will emit row_deleted(),
                // and its handlers could potentially depend on one of the methods mentioned above.
                items.unset (item);

                if (child_iter != null)
                    child_tree.remove (child_iter);

                // Also query the item's parent n_children property. In case it is zero, we update
                // the parent category's row in order to re-filter it, since empty categories should
                // not be displayed
                var parent = item.parent; // hold a reference since the item's reference will be dropped
                if (parent != null) {
                    Gdk.threads_add_idle_full (Priority.HIGH_IDLE, () => {
                        if (parent != null)
                            update_item (parent);
                        return false;
                    });
                }
            }
        }

        /**
         * Returns the Item pointed by iter, or null if the iter doesn't refer to a valid item.
         */
        public Item? get_item (Gtk.TreeIter iter) {
            Item? item;
            get (iter, Column.ITEM, out item, -1);
            return item;
        }

        /**
         * Returns the Item pointed by path, or null if the path doesn't refer to a valid item.
         */
        public Item? get_item_from_path (Gtk.TreePath path) {
            Gtk.TreeIter iter;
            if (get_iter (out iter, path))
                return get_item (iter);

            return null;
        }

        /**
         * Returns a newly-created Gtk.TreeIter pointing to the item, or null if a valid iter could
         * not be created.
         */
        public Gtk.TreeIter? get_item_iter (Item item) {
            Gtk.TreeIter? iter = null, child_iter = get_item_child_iter (item);

            // Now let's convert the child iter to a valid iter
            if (child_iter != null) {
                Gtk.TreeIter tmp_iter;
                if (convert_child_iter_to_iter (out tmp_iter, child_iter))
                    iter = tmp_iter;
            }

            return iter;
        }

        /**
         * Returns a newly-created path pointing to the item, or null in case a valid path
         * is not found.
         */
        public Gtk.TreePath? get_item_path (Item item) {
            Gtk.TreePath? path = null, child_path = get_item_child_path (item);

            // We want a filter path, not a child_model path
            if (child_path != null)
                path = convert_child_path_to_path (child_path);

            return path;
        }

        /**
         * Sets the sort function, or "unsets" it if null is passed. Please note though,
         * that unsetting the sort function doesn't bring the items back to their initial
         * order.
         */
        public void set_sort_func (owned Sidebar.SortFunc? sort_func) {
            this.sort_func = (owned)sort_func;
        }

        /**
         * Actual sort function. It simply returns zero if sort_func is null.
         */
        private int child_model_sort_func (Gtk.TreeModel model, Gtk.TreeIter a, Gtk.TreeIter b) {
            // Return zero by default, since a different value would not be reflexive nor symmetric when
            // sort_func is null.
            int sort = 0;

            Item? item_a, item_b;
            child_tree.get (a, Column.ITEM, out item_a, -1);
            child_tree.get (b, Column.ITEM, out item_b, -1);

            if (sort_func != null && item_a != null && item_b != null)
                sort = sort_func (item_a, item_b);

            return sort;
        }

        private Gtk.TreeIter? get_item_child_iter (Item item) {
            Gtk.TreeIter? child_iter = null;

            var child_node_wrapper = items.get (item);
            if (child_node_wrapper != null)
                child_iter = child_node_wrapper.iter;

            return child_iter;
        }

        private Gtk.TreePath? get_item_child_path (Item item) {
            Gtk.TreePath? child_path = null;

            var child_node_wrapper = items.get (item);
            if (child_node_wrapper != null)
                child_path = child_node_wrapper.path;

            return child_path;
        }

        /**
         * Filters the child-tree items based on their "visible" property. If the item is also
         * a category, the visibility is decided based on its number of children.
         */
        private bool filter_visible_func (Gtk.TreeModel child_model, Gtk.TreeIter iter) {
            bool item_visible = false;

            Item? item;
            child_tree.get (iter, Column.ITEM, out item, -1);

            if (item != null)
               item_visible = item.visible;

            return item_visible;
        }
    }



    /**
     * The tree that actually displays the items. All the user interaction happens here.
     */
    private class Tree : Gtk.TreeView {
        public FilteredDataModel data_model { get; set; }

        public signal void item_selected (Item item);

        public Item? selected_item {
            get { return selected; }
            set { set_selected (value, true); }
        }

        public bool editing {
            get { return text_cell.editing; }
        }

        private enum Column {
            ITEM,
            EXPANDER,
            END_PADDING,
            N_COLS
        }

        private const int LEVEL_INDENTATION = 18;

        // right-left padding. This space is added at both ends of the tree
        private const int BASE_INDENTATION = LEVEL_INDENTATION / 3;

        private Item? selected;

        private Gtk.CellRendererText text_cell;
        private CellRendererIcon activatable_cell;
        private CellRendererExpander expander_cell;


        public Tree (FilteredDataModel data_model) {
            this.data_model = data_model;
            set_model (data_model);

            enable_search = false;
            headers_visible = false;
            enable_grid_lines = Gtk.TreeViewGridLines.NONE;
            halign = valign = Gtk.Align.FILL;
            expand = true;

            // Deactivate GtkTreeView's built-in expander functionality
            expander_column = null;
            show_expanders = false;
            level_indentation = LEVEL_INDENTATION;

            var item_column = new Gtk.TreeViewColumn ();
            item_column.sizing = Gtk.TreeViewColumnSizing.FIXED;
            item_column.expand = true;

            insert_column (item_column, Column.ITEM);

            var left_spacer = new Gtk.CellRendererText ();
            left_spacer.xpad = BASE_INDENTATION / 2;
            item_column.pack_start (left_spacer, false);

            var icon_cell = new CellRendererIcon (CellRendererIcon.IconType.ICON);
            icon_cell.xpad = 3;
            item_column.pack_start (icon_cell, false);
            item_column.set_cell_data_func (icon_cell, icon_cell_data_func);

            text_cell = new Gtk.CellRendererText ();
            text_cell.editable = false;
            text_cell.ellipsize = Pango.EllipsizeMode.END;
            text_cell.xalign = 0.0f;

            text_cell.edited.connect (on_text_renderer_edited);

            item_column.pack_start (text_cell, true);
            item_column.set_cell_data_func (text_cell, name_cell_data_func);

            // add expander
            var expander_column = new Gtk.TreeViewColumn ();

            insert_column (expander_column, Column.EXPANDER);

            expander_column.visible = true;
            expander_column.expand = false;
            expander_column.sizing = Gtk.TreeViewColumnSizing.FIXED;

            activatable_cell = new CellRendererIcon (CellRendererIcon.IconType.ACTIVATABLE);
            expander_column.set_cell_data_func (activatable_cell, icon_cell_data_func);
            expander_column.pack_start (activatable_cell, false);

            expander_cell = new CellRendererExpander ();
            expander_column.pack_start (expander_cell, false);
            expander_column.set_cell_data_func (expander_cell, expander_cell_data_func);

            var end_padding_column = new Gtk.TreeViewColumn ();
            end_padding_column.sizing = Gtk.TreeViewColumnSizing.FIXED;
            end_padding_column.fixed_width = BASE_INDENTATION;
            end_padding_column.expand = false;

            insert_column (end_padding_column, Column.END_PADDING);

            // Selection
            var selection = get_selection ();
            selection.mode = Gtk.SelectionMode.SINGLE; // XXX Move to Gtk.SelectionMode.BROWSE
            selection.changed.connect (on_selection_change);

            // Styling
            var style_context = get_style_context ();
            style_context.add_class (Gtk.STYLE_CLASS_SIDEBAR);
            style_context.changed.connect (autosize_columns);

            autosize_columns ();
        }


        /**
         * Scrolls the tree to make //item// visible.
         *
         * @param item Item to scroll to.
         */
        public bool scroll_to_item (Item item) {
            bool scrolled = false;

            // Try to scroll to the respective cell
            var path = data_model.get_item_path (item);
            if (path != null) {
#if TRACE_SIDEBAR
                debug ("Tree::scroll_to_item [%s]", item.name);
#endif
                scroll_to_cell (path, null, false, 0, 0);
                scrolled = true;
            }

            return scrolled;
        }

        public void start_editing_item (Item item) {
            if (item.editable) {
#if TRACE_SIDEBAR
                debug ("Tree::start_editing_item [%s]", item.name);
#endif
                var path = data_model.get_item_path (item);
                if (path != null) {
                    // We make the text renderer temporarily editable. This is needed to prevent non-editable
                    // items from being edited when activated. The cell is made non-editable again when the
                    // editing finishes (see on_text_renderer_edited.)
                    text_cell.editable = true;
                    set_cursor_on_cell (path, get_column (Column.ITEM), text_cell, true);
                    grab_focus ();
                } else {
                    warning ("Could not edit \"%s\": path not found", item.name);
                }
            }
        }

        // Editing has finished
        private void on_text_renderer_edited (string path, string new_text) {
            // text_cell will no longer be editable
            text_cell.editable = false;

            var item = data_model.get_item_from_path (new Gtk.TreePath.from_string (path));
            if (item != null) {
#if TRACE_SIDEBAR
                debug ("Tree::on_text_renderer_edited [%s]", item.name);
#endif
                item.edited (new_text);
            }
        }

        /**
         * Resizes all the columns to their ideal widths. Useful when the style
         * information is updated.
         */
        private void autosize_columns () {
            int total_min_width = 0;
            Gtk.Requisition minimum_size, natural_size;

            // Expander size test
            var expander_column = get_column (Column.EXPANDER);

            expander_cell.get_preferred_size (this, out minimum_size, out natural_size);
            expander_column.fixed_width = natural_size.width + LEVEL_INDENTATION;

            // Activatable size test. It shares the column with the expander, so we end up
            // using the greatest width for the column.
            activatable_cell.get_preferred_size (this, out minimum_size, out natural_size);
            if (expander_column.fixed_width < natural_size.width)
                expander_column.fixed_width = natural_size.width;

            total_min_width += expander_column.fixed_width;

            // Also update size request
            set_size_request (total_min_width + 2 * LEVEL_INDENTATION + 10, -1);

            columns_autosize ();
        }

        /**
         * Updates the tree to reflect the @expanded and @collapsible properties of a category.
         * If the category is collapsible, is is expanded or collapsed based on this property;
         * otherwise we make sure the category is expanded.
         */
        public void update_expansion (Category category) {
            var path = data_model.get_item_path (category);

            if (path != null) {
#if TRACE_SIDEBAR
                debug ("Tree::update_expansion [%s]", category.name);
#endif
                if (category.expanded || !category.collapsible)
                    expand_row (path, false);
                else
                    collapse_row (path);
            }
        }

        public override void row_activated (Gtk.TreePath path, Gtk.TreeViewColumn column) {
            if (column == get_column (Column.ITEM)) {
                var item = data_model.get_item_from_path (path);
                if (item != null) {
#if TRACE_SIDEBAR
                    debug ("Tree::row_activated [%s]", item.name);
#endif
                    if (item.editable)
                        start_editing_item (item);
                    else
                        item.activated ();
                }
            }
        }

        private void on_selection_change () {
            Gtk.TreeModel? model;
            Gtk.TreeIter? iter;

            if (get_selection ().get_selected (out model, out iter)) {
                var item = get_item_from_model (model, iter);
                if (item != selected_item)
                    set_selected (item, false);
            }
        }

        private void set_selected (Item? item, bool scroll_to_item) {
            var selection = get_selection ();
            selection.changed.disconnect (on_selection_change);

            selection.unselect_all ();

            // Initial test
            if (item == null || !item.selectable)
                item = this.selected;

            if (item != null) {
                Gtk.TreeIter? to_select = null;

                if (scroll_to_item)
                    this.scroll_to_item (item);

                // Only *selectable* items can be set as selected
                if (item.selectable) {
                    // Try to get a valid iter for the item
                    to_select = data_model.get_item_iter (item);
                }

                if (to_select != null) {
                    selection.select_iter (to_select);
                    this.selected = item; // Set new item a selected

                    // Notify clients
                    item_selected (this.selected);
                }
            }

            selection.changed.connect (on_selection_change);
        }

        private static Item? get_item_from_model (Gtk.TreeModel model, Gtk.TreeIter iter) {
            var data_model = model as FilteredDataModel;
            assert (data_model != null);
            return data_model.get_item (iter);
        }

        private static void name_cell_data_func (Gtk.CellLayout layout, Gtk.CellRenderer renderer,
                                                 Gtk.TreeModel model, Gtk.TreeIter iter) {
            var text_renderer = renderer as Gtk.CellRendererText;
            assert (text_renderer != null);

            var item = get_item_from_model (model, iter);
            if (item != null) {
                var weight = Pango.Weight.NORMAL;

                var category = item as Category;
                if (category != null && !category.no_caption)
                    weight = Pango.Weight.BOLD;

                text_renderer.weight = weight;
                text_renderer.text = item.name;
            }
        }

        private void icon_cell_data_func (Gtk.CellLayout layout, Gtk.CellRenderer renderer,
                                          Gtk.TreeModel model, Gtk.TreeIter iter) {
            var icon_renderer = renderer as CellRendererIcon;
            assert (icon_renderer != null);

            bool visible = false;
            Icon? icon = null;

            var item = get_item_from_model (model, iter);
            if (item != null) {
                visible = !(item is Category);
                switch (icon_renderer.icon_type) {
                    case CellRendererIcon.IconType.ICON:
                        icon = item.icon;
                        break;
                    case CellRendererIcon.IconType.ACTIVATABLE:
                        icon = item.activatable;
                        break;
                    default:
                        warning ("Icon type %s was not handled", icon_renderer.icon_type.to_string ());
                        break;
                }
            }

            icon_renderer.visible = visible;
            icon_renderer.gicon = icon;
        }

        private void expander_cell_data_func (Gtk.CellLayout layout, Gtk.CellRenderer renderer,
                                              Gtk.TreeModel model, Gtk.TreeIter iter) {
            var expander_renderer = renderer as CellRendererExpander;
            assert (expander_renderer != null);

            bool visible = false;

            var item = get_item_from_model (model, iter);
            if (item != null) {
                var category = item as Category;

                // We could actually do better here. It should be something like
                // ... && category.n_visible_children > 0; but that doesn't matter at the moment,
                // since in such case the category would be hidden by the model. If that behavior
                // ever changes, make sure you update this portion of code to do that right.
                if (category != null)
                    visible = category.collapsible && category.n_children > 0;
            }

            expander_renderer.visible = visible;
        }

        public override bool key_release_event (Gdk.EventKey event) {
           if (selected_item != null) {
                switch (event.keyval) {
                    case Gdk.Key.F2:
                       var modifiers = Gtk.accelerator_get_default_mod_mask ();
                        // try to start editing selected item
                        if ((event.state & modifiers) == 0 && selected_item.editable)
                            start_editing_item (selected_item);
                        break;
                }
            }

            return base.key_release_event (event);
        }

        public override bool popup_menu () {
            return popup_context_menu (selected_item, null);
        }

        private bool popup_context_menu (Item item, Gdk.EventButton? event) {
#if TRACE_SIDEBAR
            debug ("popup_context_menu [%s]", item.name);
#endif
            var time = (event != null) ? event.time : Gtk.get_current_event_time ();
            var button = (event != null) ? event.button : 0;

            var menu = item.get_context_menu ();

            if (menu != null) {
                menu.attach_to_widget (this.parent, null);
                menu.popup (null, null, null, button, time);
                return true;
            }

            return false;
        }

        public override bool button_press_event (Gdk.EventButton event) {
            Gtk.TreePath path;
            Gtk.TreeViewColumn column;

            int x = (int)event.x, y = (int)event.y, cell_x, cell_y;

            if (get_path_at_pos (x, y, out path, out column, out cell_x, out cell_y)) {
                var item = data_model.get_item_from_path (path);

                if (item != null && event.type == Gdk.EventType.BUTTON_PRESS) {
                    // This is implemented in C as a union, so there's no other way around than doing
                    // pointer casting when working from Vala.
                    var ev = (Gdk.Event*)(&event);

                    if (ev->triggers_context_menu ()) {
                        popup_context_menu (item, event);
                    } else if (event.button == Gdk.BUTTON_PRIMARY) {
                        if (over_activatable (item, column, cell_x, cell_y)) {
                            item.action_activated (event.time);
                        } else if (over_expander (item, column, cell_x, cell_y)) {
#if TRACE_SIDEBAR
                            debug ("Tree: expander clicked");
#endif
                            var category = item as Category;
                            if (category != null)
                                category.expanded = !category.expanded;
                        }
                    }
                }
            }

            return base.button_press_event (event);
        }

        private bool over_activatable (Item item, Gtk.TreeViewColumn col, int x, int y) {
            if (item.activatable != null) {
                int cell_x, cell_width;
                col.cell_get_position (activatable_cell, out cell_x, out cell_width);

                if (x > cell_x && x < cell_x + cell_width)
                    return true;
            }

            return false;
        }

        private bool over_expander (Item item, Gtk.TreeViewColumn col, int x, int y) {
            var category = item as Category;
            if (category != null && category.collapsible) {
                int cell_x, cell_width;
                col.cell_get_position (expander_cell, out cell_x, out cell_width);

                // If the item is not selectable (see the explanation of why an item could
                // not be selectable at Item.selectable), convert its entire area into
                // an expander (and make it easier for the user to expand/collapse items).
                if (!category.selectable || x > cell_x && x < cell_x + cell_width)
                    return true;
            }

            return false;
        }
    }



    /**
     * Emitted when the sidebar selection changes.
     *
     * @param item Selected item.
     * @since 0.2
     */
    public virtual signal void item_selected (Item? item) {
#if TRACE_SIDEBAR
        debug ("item_selected [%s]", item != null ? item.name : "null");
#endif
    }

    /**
     * A {@link Granite.Widgets.Sidebar.SortFunc} should return a negative integer, zero, or a
     * positive integer if ''a'' sorts //before// ''b'', ''a'' sorts //with// ''b'', or ''a'' sorts
     * //after// ''b'' respectively. If two items compare as equal, their order in the sorted
     * sidebar is undefined.
     *
     * In order to ensure that the sidebar behaves as expected, the {@link Granite.Widgets.Sidebar.SortFunc}
     * must define a partial order on the sidebar tree; i.e. it must be reflexive, antisymmetric and
     * transitive.
     *
     * (Same description as {@link Gtk.TreeIterCompareFunc}.)
     *
     * @param a First item.
     * @param b Second item.
     * @return A //negative// integer if //a// sorts after //b//, //zero// if //a// equals //b//,
     *         or a //positive// integer if //a// sorts before //b//.
     * @since 0.2
     */
    public delegate int SortFunc (Item a, Item b);

    /**
     * Root-level category. This category represents the first-level sidebar items. It is treated
     * differently than the other categories: for this category, ''all'' the Item and Category
     * properties are ignored. It only serves as an item container, and also allows the sidebar to
     * connect to its {@link Granite.Widgets.Sidebar.Category.child_added} and
     * {@link Granite.Widgets.Sidebar.Category.child_removed} signals in order to monitor
     * new children additions/removals.
     *
     * @since 0.2
     */
    public Category root { get; private set; default = new Category (); }

    /**
     * The current selected item. Setting its value to //null// or an invalid
     * (e.g. unselectable) item has no effect over the current selection and nothing
     * is changed.
     *
     * @since 0.2
     */
    public Item? selected {
        get { return tree.selected_item; }
        set { tree.selected_item = value; }
    }

    /**
     * Whether an item is being edited.
     *
     * @see Granite.Widgets.Sidebar.start_editing_item
     * @since 0.2
     */
    public bool editing {
        get { return tree.editing; }
    }

    private Tree tree;
    private FilteredDataModel data_model { get { return tree.data_model; } }


    /**
     * Creates a new {@link Granite.Widgets.Sidebar}.
     *
     * @return (transfer full) a new {@link Granite.Widgets.Sidebar}.
     * @since 0.2
     */
    public Sidebar () {
        var model = new FilteredDataModel ();

        push_composite_child ();
        tree = new Tree (model);
        tree.set_composite_name ("treeview");
        pop_composite_child ();

        set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        add (tree);
        show_all ();

        tree.item_selected.connect ( (item) => item_selected (item) );

        // Initialize item monitor
        root.child_added.connect (add_item);
        root.child_removed.connect (remove_item);
    }

    /**
     * Checks whether //item// is part of the sidebar.
     *
     * @param item The item to query.
     * @return //true// if the item belongs to the sidebar; //false// otherwise.
     * @since 0.2
     */
    public bool has_item (Item item) {
        return data_model.has_item (item);
    }

    /**
     * Sets the method used for sorting items.
     *
     * @param sort_func The method to use for sorting items.
     * @see Granite.Widgets.Sidebar.SortFunc
     * @since 0.2
     */
    public void set_sort_func (owned SortFunc sort_func) {
        data_model.set_sort_func ((owned)sort_func);
    }

    /**
     * If //item// is editable, this activates the editor; otherwise, it does nothing. If an item
     * was already being edited, this will fail.
     *
     * @param item Item to edit.
     * @see Granite.Widgets.Sidebar.Item.editable
     * @see Granite.Widgets.Sidebar.editing
     * @since 0.2
     */
    public void start_editing_item (Item item) requires (item.editable && has_item (item) && !editing) {
        tree.start_editing_item (item);
    }

    /**
     * Recursively expands all the categories.
     *
     * @see Granite.Widgets.Sidebar.Category.expanded
     * @since 0.2
     */
    public void expand_all () {
        expand_with_children (root, true);
    }

    /**
     * Recursively collapses all the collapsible categories.
     *
     * @see Granite.Widgets.Sidebar.Category.expanded
     * @see Granite.Widgets.Sidebar.Category.collapsible
     * @since 0.2
     */
    public void collapse_all () {
        expand_with_children (root, false);
    }

    /**
     * Recursively sets the {@link Granite.Widgets.Sidebar.Category.expanded} property
     * of //category// and its child categories to the value specified, so this can
     * be used for both expanding and collapsing.
     *
     * @param category Category where expansion begins.
     * @param expand Whether categories will be expanded or collapsed.
     * @since 0.2
     */
    public void expand_with_children (Category category, bool expand) {
        category.expanded = expand;

        foreach (var item in category.get_children ()) {
            var child_category = item as Category;
            if (child_category != null)
                expand_with_children (child_category, expand);
        }
    }

    /**
     * Recursively sets the {@link Granite.Widgets.Sidebar.Category.expanded} property
     * of //category// and its parent categories to the value specified, so this can
     * be used for both expanding and collapsing.
     *
     * @param category Category where expansion begins.
     * @param expand Whether categories will be expanded or collapsed.
     * @since 0.2
     */
    public void expand_with_parents (Category category, bool expand) {
        category.expanded = expand;

        var parent = category.parent;
        if (parent != null && parent != this.root)
            expand_with_parents (parent, expand);
    }

    /**
     * Scrolls the sidebar tree to make //item// visible.
     *
     * If //expand_parents// is //true//, expand_with_parents() is called for the item's
     * parent category to make sure it's not obscured behind a group of collapsed categories.
     *
     * @param item Item to scroll to.
     * @param expand_parents Whether to expand item's parent categories in case they are collapsed.
     * @return //true// if successful; //false// otherwise.
     * @since 0.2
     */
    public bool scroll_to_item (Item item, bool expand_parents = true) requires (has_item (item)) {
        if (expand_parents && item.parent != null)
            expand_with_parents (item.parent, true);

        return tree.scroll_to_item (item);
    }

    /**
     * Adds an item in response to the {@link Granite.Widgets.Sidebar.Category.child_added}
     * signal.
     *
     * This method is recursively signaled. While it is first emitted in response to the
     * root's child_added() signal, successive calls are fired by child categories, since
     * we set this method as handler for their child_added() signal. In fact, all the item
     * monitors are connected here, and disconnected in remove_item().
     */
    private void add_item (Item item) requires (!has_item (item)) {
        data_model.add_item (item);

        // Monitor object properties
        item.changed.connect (on_item_property_changed);

        // If it's a category, also add children
        var category = item as Category;
        if (category != null) {
            category.child_added.connect (add_item);
            category.child_removed.connect (remove_item);

            tree.update_expansion (category);

            foreach (var child in category.get_children ()) {
                // This will always be faster than the normal recursive implementation
                Gdk.threads_add_idle_full (Priority.HIGH_IDLE, () => {
                    add_item (child);
                    return false;
                });
            }
        }
    }

    /**
     * Removes an item in response to the {@link Granite.Widgets.Sidebar.Category.child_removed}
     * signal.
     *
     * This method also disconnects the handlers set by add_item().
     */
    private void remove_item (Item item) requires (has_item (item)) {
        // Disconnect everything we connected in add_item()
        item.changed.disconnect (on_item_property_changed);

        var category = item as Category;
        if (category != null) {
            category.child_added.disconnect (add_item);
            category.child_removed.disconnect (remove_item);
        }

        data_model.remove_item (item);
    }

    /**
     * Updates an item in response to the {@link Granite.Widgets.Sidebar.Item.changed} signal.
     */
    private void on_item_property_changed (Item item, string prop) requires (has_item (item)) {
        if (prop == "parent") // Currently only handled by add_item() and remove_item()
            return;

        data_model.update_item (item);

        var category = item as Category;
        if (category != null)
            tree.update_expansion (category);
    }
}
