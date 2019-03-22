public class Settings : Granite.Services.Settings {

    public string default_currency { get; set; }

    public Settings ()  {
        base ("com.github.jeremyvaartjes.subminder.settings");
    }
}