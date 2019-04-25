//                                         
//   _____     _   _____ _       _         
//  |   __|_ _| |_|     |_|___ _| |___ ___ 
//  |__   | | | . | | | | |   | . | -_|  _|
//  |_____|___|___|_|_|_|_|_|_|___|___|_|  
//                                         
//                            Version 1.1.0
//  
//        Jeremy Vaartjes<jeremy@vaartj.es>
//  
//  =======================================
//  
//  Copyright (C) 2019 Jeremy Vaartjes
//  
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//  
//  =======================================
//  

public class AddSubscriptionDialog : Gtk.Dialog {
    SubMinder rootApp;
    Gtk.TreeView templateView;
    Gtk.ListStore templateListStore;

    public AddSubscriptionDialog(SubMinder *appObj){
        rootApp = appObj;
        this.deletable = false;
        this.modal = true;
        title = _("Create Subscription");
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        
        var createButton = new Gtk.Button.with_label (_("Create"));
        createButton.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        createButton.clicked.connect (saveDialog);

        var cancelButton = new Gtk.Button.with_label (_("Cancel"));
        cancelButton.clicked.connect (() => {this.destroy ();});

        templateListStore = new Gtk.ListStore (1, typeof (string));

        string[] systemDirs = Environment.get_system_data_dirs ();
        foreach (var dir in systemDirs) {
            var file = File.new_for_path(dir + "/com.github.jeremyvaartjes.subminder/com.github.jeremyvaartjes.subminder.templates.json");
            if (file.query_exists ()){
                try{
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_file (dir + "/com.github.jeremyvaartjes.subminder/com.github.jeremyvaartjes.subminder.templates.json");
                    Json.Node node = parser.get_root ();
                    Json.Array templateArray = node.get_object ().get_array_member("templates");
                    var tempList = new List<string>();
                    foreach (Json.Node n in templateArray.get_elements ()) {
                        Json.Object o = n.get_object ();
                        tempList.append(o.get_string_member("name"));
                    }
                    tempList.sort(strcmp);
                    tempList.foreach ((entry) => {
                        Gtk.TreeIter iter;
                        templateListStore.append (out iter);
                        templateListStore.set (iter, 0, entry);
                    });
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
            }
        }

        Gtk.TreeIter iter;
        templateListStore.append (out iter);
        templateListStore.set (iter, 0, _("Other Subscription"));

        var scroller = new Gtk.ScrolledWindow(null, null);
        templateView = new Gtk.TreeView.with_model (templateListStore);
        var templateListCell = new Gtk.CellRendererText ();
        templateView.insert_column_with_attributes (-1, _("Template"), templateListCell, "text", 0);
        templateView.headers_visible = false;
        scroller.add(templateView);
        scroller.width_request = 400;
        scroller.height_request = 300;

        var title = new Gtk.Label(_("Choose a subscription template"));
        title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var suggestionLabel = new Gtk.Label(_("Got a suggestion? <a href=\"https://github.com/jeremyvaartjes/subminder/issues\">Post it here</a>."));
        suggestionLabel.use_markup = true;

        var searchField = new Gtk.SearchEntry();
        searchField.search_changed.connect(() => {
            if(searchField.text == ""){
                templateView.model = templateListStore;
            }else{
                var searchListStore = new Gtk.ListStore (1, typeof (string));
                var tempList = new List<string>();
                templateListStore.foreach ((model, path, iter2) => {
                    string entry;
                    model.get(iter2, 0, out entry);
                    if(entry.down().contains(searchField.text.down())){
                        tempList.append(entry);
                    }
                    return false;
                });
                tempList.sort(strcmp);
                tempList.foreach ((entry) => {
                    Gtk.TreeIter iter2;
                    searchListStore.append (out iter2);
                    searchListStore.set (iter2, 0, entry);
                });
                templateView.model = searchListStore;
            }
        });

        var grid = new Gtk.Grid ();
        grid.row_spacing = 12;
        grid.column_spacing = 12;
        grid.margin_start = 12;
        grid.margin_end = 12;
        grid.attach (title, 0, 0, 2, 1);
        grid.attach (searchField, 0, 1, 2, 1);
        grid.attach (scroller, 0, 2, 2, 1);
        grid.attach (suggestionLabel, 0, 3, 2, 1);
        grid.attach (createButton, 1, 4, 1, 1);
        grid.attach (cancelButton, 0, 4, 1, 1);

        ((Gtk.Container)get_content_area ()).add (grid);
    }

    private void saveDialog () {
        Gtk.TreeModel model;
        Gtk.TreeIter iter;
        string template;
        if(templateView.get_selection().get_selected (out model, out iter)){
            model.get (iter, 0, out template);
            var nSub = new Subscription();
            nSub.name = template;
            nSub.currency = rootApp.settings.default_currency;
            try{
                nSub.newFile();
                rootApp.addSubscription(nSub);
            }catch(Error e){
                stdout.printf("Error: %s\n", e.message);
            }
            rootApp.showSub(nSub.fileId);
            this.destroy ();
        }
    }
}
