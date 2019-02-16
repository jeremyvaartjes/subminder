public class SubMinder : Gtk.Application {

    public SubMinder () {
        Object (
            application_id: "com.github.jeremyvaartjes.subminder",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.default_height = 700;
        main_window.default_width = 450;
        main_window.title = _("SubMinder");
        main_window.show_all ();
    }

    public static int main (string[] args) {
        var app = new SubMinder ();
        return app.run (args);
    }
}