public class Daemon : GLib.Application {
    Gee.TreeMap<int, DateTime> notificationHistory;

    public Daemon(){
        notificationHistory = new Gee.TreeMap<int, DateTime>();
        checkNotifications();
        // check notifications every 3 hours
        Timeout.add_seconds (10800, () => {
            checkNotifications();
            return true;
        });
    }

    protected override void activate () {
        Gtk.main ();
    }

    private void checkNotifications(){
        int yearNow, monthNow, dayNow;
        var curTime = new DateTime.now_local();
        curTime.get_ymd(out yearNow, out monthNow, out dayNow);

        var subs = new Gee.TreeMap<int, Subscription>();
        Gee.ArrayList<int> existingSubs = Subscription.getFileList();
        foreach (var entry in existingSubs) {
            if(!notificationHistory.has_key(entry)){
                try{
                    Subscription sub = new Subscription();
                    sub.read(entry);
                    subs[sub.fileId] = sub;
                }catch(IOError e){
                    stdout.printf("Error: %s\n", e.message);
                }catch(Error e){
                    stdout.printf("Error: %s\n", e.message);
                }
            }else{
                int yearNot, monthNot, dayNot;
                notificationHistory[entry].get_ymd(out yearNot, out monthNot, out dayNot);
                if(yearNot != yearNow || monthNot != monthNow || dayNot != dayNow){
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
        }

        foreach (var entry in subs.entries) {
            int yearNot, monthNot, dayNot, yearBill, monthBill, dayBill;
            entry.value.nextNotification.get_ymd(out yearNot, out monthNot, out dayNot);
            entry.value.nextBillDate.get_ymd(out yearBill, out monthBill, out dayBill);
            if(yearNot == yearNow && monthNot == monthNow && dayNot == dayNow){
                notificationHistory[entry.key] = curTime;
                string notifBody;
                if(yearNot == yearBill && monthNot == monthBill && dayNot == dayBill){
                    notifBody = _("Next payment Today");
                }else{
                    notifBody = _("Next payment on ") + entry.value.nextBillDate.format(Granite.DateTime.get_default_date_format(true, true, true));
                }
                try {
                    Process.spawn_command_line_async ("com.github.jeremyvaartjes.subminder --notif --notifId="+entry.key.to_string()+" --notifTitle=\""+entry.value.name+"\" --notifBody=\""+notifBody+"\"");
                } catch (SpawnError e) {
                    print ("Error: %s\n", e.message);
                }
            }
        }
    }

    public static int main (string[] args) {
        var app = new Daemon ();
        return app.run (args);
    }
}