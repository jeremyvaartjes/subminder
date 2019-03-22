public class AddSubscriptionDialog : Gtk.Dialog {
    SubMinder rootApp;
    Gtk.TreeView templateView;

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

        var templateListStore = new Gtk.ListStore (1, typeof (string));
        Gtk.TreeIter iter;

        string[] systemDirs = Environment.get_system_data_dirs ();
        foreach (var dir in systemDirs) {
            var file = File.new_for_path(dir + "/com.github.jeremyvaartjes.subminder/com.github.jeremyvaartjes.subminder.templates.json");
            if (file.query_exists ()){
                Json.Parser parser = new Json.Parser ();
                parser.load_from_file (dir + "/com.github.jeremyvaartjes.subminder/com.github.jeremyvaartjes.subminder.templates.json");
                Json.Node node = parser.get_root ();
                Json.Array templateArray = node.get_object ().get_array_member("templates");
                foreach (Json.Node n in templateArray.get_elements ()) {
                    Json.Object o = n.get_object ();
                    templateListStore.append (out iter);
                    templateListStore.set (iter, 0, o.get_string_member("name"));
                }
            }
        }

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

        var grid = new Gtk.Grid ();
        grid.row_spacing = 12;
        grid.column_spacing = 12;
        grid.margin_start = 12;
        grid.margin_end = 12;
        grid.attach (title, 0, 0, 2, 1);
        grid.attach (scroller, 0, 1, 2, 1);
        grid.attach (suggestionLabel, 0, 2, 2, 1);
        grid.attach (createButton, 1, 3, 1, 1);
        grid.attach (cancelButton, 0, 3, 1, 1);

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