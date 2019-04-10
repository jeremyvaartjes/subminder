//                                         
//   _____     _   _____ _       _         
//  |   __|_ _| |_|     |_|___ _| |___ ___ 
//  |__   | | | . | | | | |   | . | -_|  _|
//  |_____|___|___|_|_|_|_|_|_|___|___|_|  
//                                         
//                            Version 1.0.1
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

public class SubMinder : Gtk.Application {

    public const OptionEntry[] SUBMINDER_OPTIONS =  {
        { "notif", 'n', 0, OptionArg.NONE, out notif,
        "Just show a notification", null},
        { "notifId", 'i', 0, OptionArg.INT, out notifId,
        "Notification ID Number", "id"},
        { "notifTitle", 't', 0, OptionArg.STRING, out notifTitle,
        "Notification Title Text", "\"Title Text\""},
        { "notifBody", 'b', 0, OptionArg.STRING, out notifBody,
        "Notification Body Text", "\"Body Text\""},
        { null }
    };

    public static bool notif;
    public static int notifId;
    public static string notifTitle;
    public static string notifBody;

    Gee.TreeMap<int, Subscription> subs;
    Gtk.ApplicationWindow mainWindow;
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
    public Settings settings;
    Gtk.Button backButton;
    Gtk.Button addSubButton;
    public Gtk.Button defaultCurrencyButton;

    public SubMinder () {
        Object (
            application_id: "com.github.jeremyvaartjes.subminder",
            flags: ApplicationFlags.FLAGS_NONE
        );

        //add_main_option_entries (SUBMINDER_OPTIONS);

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

        settings = new Settings();
    }

    public void addSubscription(Subscription sub){
        subs[sub.fileId] = sub;
        updateList();
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
            var amountStr = (entry.value.amount / 100).to_string() + ".";
            if(entry.value.amount % 100 < 10){
                amountStr += "0" + (entry.value.amount % 100).to_string();
            }else{
                amountStr += (entry.value.amount % 100).to_string();
            }
            var subCost = new Gtk.Label("$" + amountStr);
            subCost.xalign = 1;
            subCost.hexpand = true;
            subCost.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            rowGrid.attach (subCost, 1, 0, 1, 1);
            int numDays = (int)(entry.value.nextBillDate.difference(today()) / TimeSpan.DAY);
            string numDaysStr = "";
            if(numDays == 0){
                numDaysStr = _("Today");
            }else if(numDays == 1){
                numDaysStr = _("Tomorrow");
            }else{
                numDaysStr = numDays.to_string() + _(" Days");
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

    public void updateHeader(){
        if(settings.default_currency != "UNSET"){
            int total = 0;
            foreach (var entry in subs.entries) {
                double amountConverted = 0;
                if(settings.default_currency == "EUR"){
                    if(entry.value.currency == "EUR"){
                        amountConverted = entry.value.amount;
                    }else{
                        amountConverted = entry.value.amount / currency.currencyPrices[entry.value.currency];
                    }
                }else{
                    if(entry.value.currency == settings.default_currency){
                        amountConverted = entry.value.amount;
                    }else{
                        if(entry.value.currency == "EUR"){
                            amountConverted = entry.value.amount * currency.currencyPrices[entry.value.currency];
                        }else{
                            amountConverted = entry.value.amount * currency.currencyPrices[settings.default_currency] / currency.currencyPrices[entry.value.currency];
                        }
                    }
                }
                
                switch(entry.value.cycle.type){
                    case DAY:
                        total += (int)(amountConverted * 365 / entry.value.cycle.qty);
                        break;
                    case WEEK:
                        total += (int)(amountConverted * 52 / entry.value.cycle.qty);
                        break;
                    case MONTH:
                        total += (int)(amountConverted * 12 / entry.value.cycle.qty);
                        break;
                    case YEAR:
                        total += (int)(amountConverted / entry.value.cycle.qty);
                        break;
                }
            }
            int average = total / 12;
            var amountStr = (average / 100).to_string() + ".";
            if(average % 100 < 10){
                amountStr += "0" + (average % 100).to_string();
            }else{
                amountStr += (average % 100).to_string();
            }
            aCGCost.label = "$" + amountStr;
        }else{
            aCGCost.label = "";
        }
    }

    protected override void activate () {
        if(notif){
            doNotif(notifId, notifTitle, notifBody);
            notif = false;
        }else if(mainWindow == null){
            mainWindow = new Gtk.ApplicationWindow (this);
            mainWindow.default_height = 600;
            mainWindow.default_width = 450;
            mainWindow.title = _("SubMinder");

            var aCGTitle = new Gtk.Label("<b>" + _("Average Expenses") + "</b>");
            aCGTitle.use_markup = true;
            aCGTitle.xalign = 0;
            var aCGPeriod = new Gtk.Label("<small>" + _("Per Month") + "</small>");
            aCGPeriod.use_markup = true;
            aCGPeriod.xalign = 0;
            aCGCost = new Gtk.Label("$0.00");

            var averageCostGrid = new Gtk.Grid();
            averageCostGrid.column_spacing = 15;
            averageCostGrid.attach (aCGTitle, 0, 0, 1, 1);
            averageCostGrid.attach (aCGPeriod, 0, 1, 1, 1);
            averageCostGrid.attach (aCGCost, 1, 0, 1, 2);

            addSubButton = new Gtk.Button.from_icon_name("list-add", LARGE_TOOLBAR);
            addSubButton.clicked.connect(() => {
                var dialog = new AddSubscriptionDialog (this);
                dialog.transient_for = this.mainWindow;
                dialog.show_all ();
            });

            backButton = new Gtk.Button.with_label(_("Subscription List"));
            backButton.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
            backButton.clicked.connect(() => {
                subDetailsGrid.hide();
                scroller.show_all();
                backButton.hide();
                addSubButton.show();
                selectedRowId = 0;
            });

            defaultCurrencyButton = new Gtk.Button.with_label(settings.default_currency);
            if(settings.default_currency == "UNSET"){
                defaultCurrencyButton.label = _("Set Default Currency");
            }
            defaultCurrencyButton.clicked.connect(() => {
                setDefaultCurrency();
            });

            var header = new Gtk.HeaderBar();
            header.show_close_button = true;
            header.set_custom_title(averageCostGrid);
            header.pack_start(addSubButton);
            header.pack_start(backButton);
            header.pack_end(defaultCurrencyButton);
            mainWindow.set_titlebar(header);

            // fileId, name, description, amount, currency, nextBillDate
            /*subListStore = new Gtk.ListStore(6, typeof(int), typeof(string), typeof(string), typeof(int), typeof(Currency), typeof(Interval));*/
            subListView = new Gtk.ListBox();
            subListView.selection_mode = SINGLE;
            subListView.row_selected.connect(() => {
                var row = (SubscriptionListRow) subListView.get_selected_row();
                if(row != null){
                    showSub(row.fileId);
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
            subDetailsCycleQty.value_changed.connect(() => {
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
            subDetailsRemindMeQty.value_changed.connect(() => {
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
            subDetailsAmount = new Gtk.SpinButton.with_range(0, 10000000, 0.01);
            subDetailsAmount.digits = 2;
            subDetailsAmount.value_changed.connect(() => {
                if(selectedRowId != 0){
                    stdout.printf("%d\n", (int)(subDetailsAmount.value * 100));
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
            subDetailsCycleTypeStore.set (iter, 0, _("Days"));
            subDetailsCycleTypeStore.append (out iter);
            subDetailsCycleTypeStore.set (iter, 0, _("Weeks"));
            subDetailsCycleTypeStore.append (out iter);
            subDetailsCycleTypeStore.set (iter, 0, _("Months"));
            subDetailsCycleTypeStore.append (out iter);
            subDetailsCycleTypeStore.set (iter, 0, _("Years"));
            Gtk.CellRendererText subDetailsCycleTypeRenderer = new Gtk.CellRendererText ();
            subDetailsCycleType.pack_start (subDetailsCycleTypeRenderer, true);
            subDetailsCycleType.add_attribute (subDetailsCycleTypeRenderer, "text", 0);
            subDetailsCycleType.active = 0;
            subDetailsRemindMeTypeStore.append (out iter);
            subDetailsRemindMeTypeStore.set (iter, 0, _("Never"));
            subDetailsRemindMeTypeStore.append (out iter);
            subDetailsRemindMeTypeStore.set (iter, 0, _("Same Day"));
            subDetailsRemindMeTypeStore.append (out iter);
            subDetailsRemindMeTypeStore.set (iter, 0, _("Days"));
            subDetailsRemindMeTypeStore.append (out iter);
            subDetailsRemindMeTypeStore.set (iter, 0, _("Weeks"));
            subDetailsRemindMeTypeStore.append (out iter);
            subDetailsRemindMeTypeStore.set (iter, 0, _("Months"));
            subDetailsRemindMeTypeStore.append (out iter);
            subDetailsRemindMeTypeStore.set (iter, 0, _("Years"));
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
            mainWindow.add(hStackMain);

            mainWindow.show_all ();
            subDetailsGrid.hide();
            subListView.unselect_all();
            scroller.show_all();
            backButton.hide();
            addSubButton.show();

            checkForDefaultCurrency();
        }
    }

    private void checkForDefaultCurrency(){
        if(settings.default_currency == "UNSET"){
            setDefaultCurrency();
        }
    }

    private void setDefaultCurrency(){
        var dialog = new DefaultCurrencyDialog (this, currency);
        dialog.transient_for = this.mainWindow;
        dialog.show_all ();
    }

    public void showSub(int fileId){
        selectedRowId = fileId;
        subDetailsName.text = subs[fileId].name;
        subDetailsDesc.text = subs[fileId].description;
        subDetailsAmount.value = subs[fileId].amount / 100.0;
        subDetailsFBDate.date = subs[fileId].firstBillDate;
        var i = 0;
        foreach (var entry in currency.currencies.entries) {
            if(entry.key == subs[fileId].currency){
                subDetailsCrncy.active = i;
                break;
            }else{
                i++;
            }
        }
        subDetailsCycleQty.value = subs[fileId].cycle.qty;
        if(subs[fileId].cycle.type == DAY){
            subDetailsCycleType.active = 0;
        }else if(subs[fileId].cycle.type == WEEK){
            subDetailsCycleType.active = 1;
        }else if(subs[fileId].cycle.type == MONTH){
            subDetailsCycleType.active = 2;
        }else if(subs[fileId].cycle.type == YEAR){
            subDetailsCycleType.active = 3;
        }
        if(subs[fileId].remindMe.qty == -1){
            subDetailsRemindMeQty.value = 1;
            subDetailsRemindMeType.active = 0;
        }else if(subs[fileId].remindMe.qty == 0){
            subDetailsRemindMeQty.value = 1;
            subDetailsRemindMeType.active = 1;
        }else{
            subDetailsRemindMeQty.value = subs[fileId].remindMe.qty;
            if(subs[fileId].remindMe.type == DAY){
                subDetailsRemindMeType.active = 2;
            }else if(subs[fileId].remindMe.type == WEEK){
                subDetailsRemindMeType.active = 3;
            }else if(subs[fileId].remindMe.type == MONTH){
                subDetailsRemindMeType.active = 4;
            }else if(subs[fileId].remindMe.type == YEAR){
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

    public void doNotif(int id, string title, string body){
        var notification = new GLib.Notification (title);
        notification.set_body (body);
        string uid = "com.github.jeremyvaartjes.subminder-"+id.to_string();
        this.send_notification (uid, notification);
    }

    public static int main (string[] args) {
        OptionContext context = new OptionContext ("");
        context.add_main_entries (SUBMINDER_OPTIONS, null);

        try {
            context.parse (ref args);
        } catch (OptionError e) {
            error (e.message);
        }

        var app = new SubMinder ();

        if (notif) {
            app.register();
            app.doNotif(notifId, notifTitle, notifBody);
            return 0;
        }else{
            if (!Thread.supported ()) {
                stderr.printf (_("Cannot run without thread support.\n"));
                return 1;
            }
            return app.run (args);
        }
    }
}