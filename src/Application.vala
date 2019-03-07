public class SubMinder : Gtk.Application {

    Gee.TreeMap<int, Subscription> subs;
    Gtk.ListBox subListView;
    Gtk.Label aCGCost;
    Gtk.Entry subDetailsName;
    Gtk.Entry subDetailsDesc;
    Granite.Widgets.DatePicker subDetailsFBDate;
    Gtk.SpinButton subDetailsCycleQty;
    Gtk.SpinButton subDetailsRemindMeQty;
    Gtk.ComboBox subDetailsCycleType;
    Gtk.ComboBox subDetailsRemindMeType;
    Gtk.ComboBox subDetailsCrncy;
    Gtk.SpinButton subDetailsAmount;
    Gtk.Grid subDetailsGrid;
    Gtk.ScrolledWindow scroller;
    SMCurrency currency;
    Gtk.ListStore currencyListStore;
    Gtk.ListStore subDetailsCycleTypeStore;
    Gtk.ListStore subDetailsRemindMeTypeStore;
    int selectedRowId;

    public SubMinder () {
        Object (
            application_id: "com.github.jeremyvaartjes.subminder",
            flags: ApplicationFlags.FLAGS_NONE
        );

        try{
            currency = new SMCurrency();
        }catch(IOError e){
            stdout.printf("Error: %s\n", e.message);
        }catch(Error e){
            stdout.printf("Error: %s\n", e.message);
        }
        
        selectedRowId = 0;

        subs = new Gee.TreeMap<int, Subscription>();
        Gee.ArrayList<int> existingSubs = Subscription.getFileList();
        foreach (var entry in existingSubs) {
            try{
                Subscription sub = new Subscription();
                sub.read(entry);
                subs[sub.fileId] = sub;
            }catch(IOError e){
                stdout.printf("Error: %s\n", e.message);
            }catch(Error e){
                stdout.printf("Error: %s\n", e.message);
            }
        }
    }

    private void updateList(){
        /*Gtk.TreeIter iter;
        subListStore.clear();
        foreach (var entry in subs.entries) {
            Interval interval = { 0, IntervalType.DAY };
            subListStore.append (out iter);
            subListStore.set (iter, 0, entry.key, 1, entry.value.name, 2, entry.value.description, 3, entry.value.amount, 4, entry.value.currency, 5, interval);
        }
        subListView.bind_model(subListStore);*/
        foreach (var row in subListView.get_children()) {
            subListView.remove(row);
        }

        foreach (var entry in subs.entries) {
            var row = new SubscriptionListRow();
            var rowGrid = new Gtk.Grid();
            rowGrid.margin = 6;
            row.add(rowGrid);

            row.fileId = entry.key;
            row.subName = entry.value.name;
            
            var subName = new Gtk.Label(entry.value.name);
            subName.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            subName.xalign = 0;
            rowGrid.attach (subName, 0, 0, 1, 1);
            var subDesc = new Gtk.Label(entry.value.description);
            subDesc.xalign = 0;
            rowGrid.attach (subDesc, 0, 1, 1, 1);
            var amountStr = (entry.value.amount / 100).to_string() + "." + (entry.value.amount % 100).to_string();
            if(entry.value.amount % 100 == 0){
                amountStr += "0";
            }
            var subCost = new Gtk.Label("$" + amountStr);
            subCost.xalign = 1;
            subCost.hexpand = true;
            subCost.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            rowGrid.attach (subCost, 1, 0, 1, 1);
            int numDays = (int)(entry.value.nextBillDate.difference(new DateTime.now_local()) / TimeSpan.DAY);
            string numDaysStr = "";
            if(numDays == 0){
                numDaysStr = "Today";
            }else if(numDays == 1){
                numDaysStr = "Tomorrow";
            }else{
                numDaysStr = numDays.to_string() + " Days";
            }
            var subNextBill = new Gtk.Label(numDaysStr);
            subNextBill.xalign = 1;
            subNextBill.hexpand = true;
            rowGrid.attach (subNextBill, 1, 1, 1, 1);
            subListView.add(row);
        }
        subListView.show_all();
        subListView.unselect_all();
    }

    private void updateHeader(){
        int total = 0;
        foreach (var entry in subs.entries) {
            switch(entry.value.cycle.type){
                case DAY:
                    total += entry.value.amount * 365 / entry.value.cycle.qty;
                    break;
                case WEEK:
                    total += entry.value.amount * 52 / entry.value.cycle.qty;
                    break;
                case MONTH:
                    total += entry.value.amount * 12 / entry.value.cycle.qty;
                    break;
                case YEAR:
                    total += entry.value.amount / entry.value.cycle.qty;
                    break;
            }
        }
        int average = total / 12;
        var amountStr = (average / 100).to_string() + "." + (average % 100).to_string();
        if(average % 100 == 0){
            amountStr += "0";
        }
        aCGCost.label = "$" + amountStr;
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.default_height = 600;
        main_window.default_width = 450;
        main_window.title = _("SubMinder");

        var aCGTitle = new Gtk.Label(_("<b>Average Expenses</b>"));
        aCGTitle.use_markup = true;
        aCGTitle.xalign = 0;
        var aCGPeriod = new Gtk.Label(_("<small>Per Month</small>"));
        aCGPeriod.use_markup = true;
        aCGPeriod.xalign = 0;
        aCGCost = new Gtk.Label(_("$0.00"));

        var averageCostGrid = new Gtk.Grid();
        averageCostGrid.column_spacing = 15;
        averageCostGrid.attach (aCGTitle, 0, 0, 1, 1);
        averageCostGrid.attach (aCGPeriod, 0, 1, 1, 1);
        averageCostGrid.attach (aCGCost, 1, 0, 1, 2);

        var addSubButton = new Gtk.Button.from_icon_name("list-add", LARGE_TOOLBAR);
        addSubButton.clicked.connect(() => {
            var nSub = new Subscription();
            nSub.name = "Testing";
            subs[subs.size + 1] = nSub;
            updateList();
        });

        var backButton = new Gtk.Button.with_label(_("Subscription List"));
        backButton.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
        backButton.clicked.connect(() => {
            subDetailsGrid.hide();
            scroller.show_all();
            backButton.hide();
            addSubButton.show();
            selectedRowId = 0;
        });

        var header = new Gtk.HeaderBar();
        header.show_close_button = true;
        header.set_custom_title(averageCostGrid);
        header.pack_start(addSubButton);
        header.pack_start(backButton);
        main_window.set_titlebar(header);

        // fileId, name, description, amount, currency, nextBillDate
        /*subListStore = new Gtk.ListStore(6, typeof(int), typeof(string), typeof(string), typeof(int), typeof(Currency), typeof(Interval));*/
        subListView = new Gtk.ListBox();
        subListView.selection_mode = SINGLE;
        subListView.row_selected.connect(() => {
            var row = (SubscriptionListRow) subListView.get_selected_row();
            if(row != null){
                selectedRowId = row.fileId;
                subDetailsName.text = subs[row.fileId].name;
                subDetailsDesc.text = subs[row.fileId].description;
                subDetailsAmount.value = subs[row.fileId].amount / 100.0;
                subDetailsFBDate.date = subs[row.fileId].firstBillDate;
                var i = 0;
                foreach (var entry in currency.currencies.entries) {
                    if(entry.key == subs[row.fileId].currency){
                        subDetailsCrncy.active = i;
                        break;
                    }else{
                        i++;
                    }
                }
                subDetailsCycleQty.value = subs[row.fileId].cycle.qty;
                if(subs[row.fileId].cycle.type == DAY){
                    subDetailsCycleType.active = 0;
                }else if(subs[row.fileId].cycle.type == WEEK){
                    subDetailsCycleType.active = 1;
                }else if(subs[row.fileId].cycle.type == MONTH){
                    subDetailsCycleType.active = 2;
                }else if(subs[row.fileId].cycle.type == YEAR){
                    subDetailsCycleType.active = 3;
                }
                if(subs[row.fileId].remindMe.qty == -1){
                    subDetailsRemindMeQty.value = 1;
                    subDetailsRemindMeType.active = 0;
                }else if(subs[row.fileId].remindMe.qty == 0){
                    subDetailsRemindMeQty.value = 1;
                    subDetailsRemindMeType.active = 1;
                }else{
                    subDetailsRemindMeQty.value = subs[row.fileId].remindMe.qty;
                    if(subs[row.fileId].remindMe.type == DAY){
                        subDetailsRemindMeType.active = 2;
                    }else if(subs[row.fileId].remindMe.type == WEEK){
                        subDetailsRemindMeType.active = 3;
                    }else if(subs[row.fileId].remindMe.type == MONTH){
                        subDetailsRemindMeType.active = 4;
                    }else if(subs[row.fileId].remindMe.type == YEAR){
                        subDetailsRemindMeType.active = 5;
                    }
                }
                subListView.unselect_all();
                subDetailsGrid.show_all();
                scroller.hide();
                backButton.show();
                addSubButton.hide();
                if(subDetailsRemindMeType.active == 0 || subDetailsRemindMeType.active == 1){
                    subDetailsRemindMeQty.visible = false;
                }else{
                    subDetailsRemindMeQty.visible = true;
                }
            }
        });
        subListView.set_sort_func ((child1, child2) => {
            var c1 = (SubscriptionListRow) child1;
            var c2 = (SubscriptionListRow) child2;
            return c1.subName.collate(c2.subName);
        });
        /*var subListCell = new Gtk.CellRendererText ();
        subListView.insert_column_with_attributes (-1, _("Name"), subListCell, "text", 1);
        subListView.insert_column_with_attributes (-1, _("Description"), subListCell, "text", 2);
        subListView.insert_column_with_attributes (-1, _("Amount"), subListCell, "text", 3);*/

        updateList();
        updateHeader();

        subDetailsGrid = new Gtk.Grid();
        subDetailsGrid.row_spacing = 10;
        subDetailsGrid.column_spacing = 6;
        subDetailsGrid.margin = 6;
        subDetailsGrid.halign = CENTER;
        subDetailsGrid.valign = CENTER;

        var subDetailsNameLabel = new Gtk.Label(_("Name:"));
        var subDetailsDescLabel = new Gtk.Label(_("Description:"));
        var subDetailsFBDateLabel = new Gtk.Label(_("First Billing Date:"));
        var subDetailsCycleLabel = new Gtk.Label(_("Billing Cycle:"));
        var subDetailsRemindMeLabel = new Gtk.Label(_("Remind Me:"));
        var subDetailsCrncyLabel = new Gtk.Label(_("Currency:"));
        var subDetailsAmountLabel = new Gtk.Label(_("Cost:"));
        subDetailsNameLabel.xalign = 1;
        subDetailsDescLabel.xalign = 1;
        subDetailsFBDateLabel.xalign = 1;
        subDetailsCycleLabel.xalign = 1;
        subDetailsRemindMeLabel.xalign = 1;
        subDetailsCrncyLabel.xalign = 1;
        subDetailsAmountLabel.xalign = 1;
        subDetailsGrid.attach(subDetailsNameLabel, 0, 0, 1, 1);
        subDetailsGrid.attach(subDetailsDescLabel, 0, 1, 1, 1);
        subDetailsGrid.attach(subDetailsAmountLabel, 0, 2, 1, 1);
        subDetailsGrid.attach(subDetailsFBDateLabel, 0, 3, 1, 1);
        subDetailsGrid.attach(subDetailsCycleLabel, 0, 4, 1, 1);
        subDetailsGrid.attach(subDetailsRemindMeLabel, 0, 5, 1, 1);
        subDetailsGrid.attach(subDetailsCrncyLabel, 0, 6, 1, 1);

        subDetailsName = new Gtk.Entry();
        subDetailsName.changed.connect(() => {
            if(selectedRowId != 0){
                subs[selectedRowId].name = subDetailsName.text;
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
            }
        });
        subDetailsDesc = new Gtk.Entry();
        subDetailsDesc.changed.connect(() => {
            if(selectedRowId != 0){
                subs[selectedRowId].description = subDetailsDesc.text;
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
            }
        });
        subDetailsFBDate = new Granite.Widgets.DatePicker();
        subDetailsFBDate.changed.connect(() => {
            if(selectedRowId != 0){
                subs[selectedRowId].firstBillDate = subDetailsFBDate.date;
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
            }
        });
        subDetailsCycleQty = new Gtk.SpinButton.with_range(1, 10000000, 1);
        subDetailsCycleQty.changed.connect(() => {
            if(selectedRowId != 0){
                Interval newInt = { (int)subDetailsCycleQty.value, subs[selectedRowId].cycle.type };
                subs[selectedRowId].cycle = newInt;
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
                updateHeader();
            }
        });
        subDetailsCycleTypeStore = new Gtk.ListStore (1, typeof (string));
        subDetailsCycleType = new Gtk.ComboBox.with_model (subDetailsCycleTypeStore);
        subDetailsCycleType.changed.connect(() => {
            if(selectedRowId != 0){
                if(subDetailsCycleType.active == 0){
                    Interval newInt = { subs[selectedRowId].cycle.qty, DAY };
                    subs[selectedRowId].cycle = newInt;
                }else if(subDetailsCycleType.active == 1){
                    Interval newInt = { subs[selectedRowId].cycle.qty, WEEK };
                    subs[selectedRowId].cycle = newInt;
                }else if(subDetailsCycleType.active == 2){
                    Interval newInt = { subs[selectedRowId].cycle.qty, MONTH };
                    subs[selectedRowId].cycle = newInt;
                }else if(subDetailsCycleType.active == 3){
                    Interval newInt = { subs[selectedRowId].cycle.qty, YEAR };
                    subs[selectedRowId].cycle = newInt;
                }
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
                updateHeader();
            }
        });
        subDetailsRemindMeQty = new Gtk.SpinButton.with_range(1, 10000000, 1);
        subDetailsRemindMeQty.changed.connect(() => {
            if(selectedRowId != 0){
                Interval newInt = { (int)subDetailsRemindMeQty.value, subs[selectedRowId].remindMe.type };
                subs[selectedRowId].remindMe = newInt;
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
            }
        });
        subDetailsRemindMeTypeStore = new Gtk.ListStore (1, typeof (string));
        subDetailsRemindMeType = new Gtk.ComboBox.with_model (subDetailsRemindMeTypeStore);
        subDetailsRemindMeType.changed.connect(() => {
            if(selectedRowId != 0){
                if(subDetailsRemindMeType.active == 0){
                    Interval newInt = { -1, DAY };
                    subs[selectedRowId].remindMe = newInt;
                }else if(subDetailsRemindMeType.active == 1){
                    Interval newInt = { 0, DAY };
                    subs[selectedRowId].remindMe = newInt;
                }else if(subDetailsRemindMeType.active == 2){
                    Interval newInt = { subs[selectedRowId].remindMe.qty, DAY };
                    subs[selectedRowId].remindMe = newInt;
                }else if(subDetailsRemindMeType.active == 3){
                    Interval newInt = { subs[selectedRowId].remindMe.qty, WEEK };
                    subs[selectedRowId].remindMe = newInt;
                }else if(subDetailsRemindMeType.active == 4){
                    Interval newInt = { subs[selectedRowId].remindMe.qty, MONTH };
                    subs[selectedRowId].remindMe = newInt;
                }else if(subDetailsRemindMeType.active == 5){
                    Interval newInt = { subs[selectedRowId].remindMe.qty, YEAR };
                    subs[selectedRowId].remindMe = newInt;
                }
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
            }
        });
        currencyListStore = new Gtk.ListStore (1, typeof (string));
        subDetailsCrncy = new Gtk.ComboBox.with_model (currencyListStore);
        subDetailsCrncy.changed.connect(() => {
            if(selectedRowId != 0){
                Gtk.TreeIter iter;
                subDetailsCrncy.get_active_iter(out iter);
                string selectedStr = "";
                currencyListStore.get(iter, 0, &selectedStr);
                foreach (var entry in currency.currencies.entries) {
                    if(entry.key + " - " + entry.value == selectedStr){
                        subs[selectedRowId].currency = entry.key;
                        try{
                            subs[selectedRowId].write();
                        }catch(Error e){
                            stdout.printf("Error: %s\n", e.message);
                        }
                        updateList();
                        updateHeader();
                    }
                }
            }
        });
        subDetailsAmount = new Gtk.SpinButton.with_range(0, 10000000, 1);
        subDetailsAmount.digits = 2;
        subDetailsAmount.changed.connect(() => {
            if(selectedRowId != 0){
                subs[selectedRowId].amount = (int)(subDetailsAmount.value * 100);
                try{
                    subs[selectedRowId].write();
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
                updateList();
                updateHeader();
            }
        });
        subDetailsGrid.attach(subDetailsName, 1, 0, 2, 1);
        subDetailsGrid.attach(subDetailsDesc, 1, 1, 2, 1);
        subDetailsGrid.attach(subDetailsAmount, 1, 2, 2, 1);
        subDetailsGrid.attach(subDetailsFBDate, 1, 3, 2, 1);
        subDetailsGrid.attach(subDetailsCycleQty, 1, 4, 1, 1);
        subDetailsGrid.attach(subDetailsCycleType, 2, 4, 1, 1);
        subDetailsGrid.attach(subDetailsRemindMeQty, 1, 5, 1, 1);
        subDetailsGrid.attach(subDetailsRemindMeType, 2, 5, 1, 1);
        subDetailsGrid.attach(subDetailsCrncy, 1, 6, 2, 1);

        foreach (var entry in currency.currencies.entries) {
            Gtk.TreeIter iter;
            currencyListStore.append (out iter);
            currencyListStore.set (iter, 0, entry.key + " - " + entry.value);
        }
        Gtk.CellRendererText subDetailsCrncyRenderer = new Gtk.CellRendererText ();
        subDetailsCrncy.pack_start (subDetailsCrncyRenderer, true);
        subDetailsCrncy.add_attribute (subDetailsCrncyRenderer, "text", 0);
        subDetailsCrncy.active = 0;

        Gtk.TreeIter iter;
        subDetailsCycleTypeStore.append (out iter);
        subDetailsCycleTypeStore.set (iter, 0, "Days");
        subDetailsCycleTypeStore.append (out iter);
        subDetailsCycleTypeStore.set (iter, 0, "Weeks");
        subDetailsCycleTypeStore.append (out iter);
        subDetailsCycleTypeStore.set (iter, 0, "Months");
        subDetailsCycleTypeStore.append (out iter);
        subDetailsCycleTypeStore.set (iter, 0, "Years");
        Gtk.CellRendererText subDetailsCycleTypeRenderer = new Gtk.CellRendererText ();
        subDetailsCycleType.pack_start (subDetailsCycleTypeRenderer, true);
        subDetailsCycleType.add_attribute (subDetailsCycleTypeRenderer, "text", 0);
        subDetailsCycleType.active = 0;
        subDetailsRemindMeTypeStore.append (out iter);
        subDetailsRemindMeTypeStore.set (iter, 0, "Never");
        subDetailsRemindMeTypeStore.append (out iter);
        subDetailsRemindMeTypeStore.set (iter, 0, "Same Day");
        subDetailsRemindMeTypeStore.append (out iter);
        subDetailsRemindMeTypeStore.set (iter, 0, "Days");
        subDetailsRemindMeTypeStore.append (out iter);
        subDetailsRemindMeTypeStore.set (iter, 0, "Weeks");
        subDetailsRemindMeTypeStore.append (out iter);
        subDetailsRemindMeTypeStore.set (iter, 0, "Months");
        subDetailsRemindMeTypeStore.append (out iter);
        subDetailsRemindMeTypeStore.set (iter, 0, "Years");
        Gtk.CellRendererText subDetailsRemindMeTypeRenderer = new Gtk.CellRendererText ();
        subDetailsRemindMeType.pack_start (subDetailsRemindMeTypeRenderer, true);
        subDetailsRemindMeType.add_attribute (subDetailsRemindMeTypeRenderer, "text", 0);
        subDetailsRemindMeType.active = 0;

        subDetailsRemindMeType.changed.connect(() => {
            if(subDetailsRemindMeType.active == 0 || subDetailsRemindMeType.active == 1){
                subDetailsRemindMeQty.visible = false;
            }else{
                subDetailsRemindMeQty.visible = true;
            }
        });

        var deleteBtn = new Gtk.Button.with_label(_("Delete subscription"));
        deleteBtn.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        deleteBtn.margin_top = 20;
        deleteBtn.clicked.connect(() => {
            if(selectedRowId != 0){
                subs[selectedRowId].remove();
                subs.unset(selectedRowId);
                updateList();
                updateHeader();
                // Now run the "back button function" // TODO - Let them use the one function rather than copy/paste
                subDetailsGrid.hide();
                scroller.show_all();
                backButton.hide();
                addSubButton.show();
                selectedRowId = 0;
            }
        });
        subDetailsGrid.attach(deleteBtn, 0, 7, 3, 1);

        var hStackMain = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        scroller = new Gtk.ScrolledWindow(null, null);
        scroller.add(subListView);
        hStackMain.pack_start(scroller);
        hStackMain.pack_start(subDetailsGrid);
        main_window.add(hStackMain);

        main_window.show_all ();
        subDetailsGrid.hide();
        subListView.unselect_all();
        scroller.show_all();
        backButton.hide();
        addSubButton.show();
    }

    public static int main (string[] args) {
        if (!Thread.supported ()) {
            stderr.printf ("Cannot run without thread support.\n");
            return 1;
        }
        var app = new SubMinder ();
        return app.run (args);
    }
}